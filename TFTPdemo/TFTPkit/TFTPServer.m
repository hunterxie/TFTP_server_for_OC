//
//  TFTPServer.m
//  TFTPdemo
//
//  Created by xll on 2017/11/1.
//  Copyright © 2017年 xll. All rights reserved.
//

//每个块的大小
#define BLOCKSIZE (1024 * 8)

//每个包最大尝试发送次数
#define PKT_MAX_RXMT 5

//发送包后到收到ack确认的时间间隔
#define PKT_RCV_TIMEOUT 2

#import "TFTPServer.h"


@interface TFTPServer()<GCDAsyncUdpSocketDelegate>

/**
 连接当前server的host
 */
@property(nonatomic,copy)NSString *connectHost;

/**
 连接当前server的port  这个会变  如果文件发送完毕 接受第二个的时候  port会变
 */
@property(nonatomic,assign)UInt16 connectPort;

/**
 当前blocknumber  开始为1
 */
@property(nonatomic,assign)long long currentBlock;

@property(nonatomic ,strong)NSTimer *timer;//  注意:此处应该使用强引用 strong

@property(nonatomic,copy)NSString *filePath;//发送文件的本地路径

@property(nonatomic,strong)NSData *fileData;//文件的总大小

@property(nonatomic,assign)long long totalBlock;//总共数据块的数目；

@property(nonatomic,assign)int reSendTryTimes;//重发尝试次数  默认0

@property(nonatomic,weak)NSObject <TFTPServerDelegate> * delegate;
@end

@implementation TFTPServer


-(instancetype)initServerWithPort:(uint16_t)port delegate:(NSObject<TFTPServerDelegate> *)delegate
{
    self  = [super init];
    
    if (self) {
        dispatch_queue_t queue = dispatch_queue_create("TFTPDemoQueue", DISPATCH_QUEUE_SERIAL);
        
        _delegate = delegate;
        
        _currentBlock = 1;
        
        _reSendTryTimes = 0;
        
        _udpSocket = [[GCDAsyncUdpSocket alloc]initWithDelegate:self delegateQueue:queue];
        [_udpSocket bindToPort:port error:nil];
        [_udpSocket setMaxSendBufferSize:(uint16_t)(BLOCKSIZE * 9)];
        
        __weak typeof(self)weakSelf = self;
        [_udpSocket setReceiveFilter:^BOOL(NSData * _Nonnull data, NSData * _Nonnull address, id  _Nullable __autoreleasing * _Nonnull context) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            
            if (!strongSelf.connectHost) {
                strongSelf.connectHost = [GCDAsyncUdpSocket hostFromAddress:address];
                strongSelf.connectPort = [GCDAsyncUdpSocket portFromAddress:address];
                NSLog(@"Connect:host:%@,port:%d",strongSelf.connectHost,strongSelf.connectPort);
            }
//            NSLog(@"new:%@---%d\nold:%@---%d",[GCDAsyncUdpSocket hostFromAddress:address],[GCDAsyncUdpSocket portFromAddress:address],strongSelf.connectHost,strongSelf.connectPort);
            TFTPPacket *packet = [TFTPPacket deserializeFrom:data];
            
            if (packet && [strongSelf handleRecievePacket:packet]) {
                return YES;
            }
            
            return NO;
        } withQueue:queue];
    }
    
    return self;
}
-(BOOL)handleRecievePacket:(TFTPPacket *)packet
{
    if ([packet isKindOfClass:[TFTPReadRequest class]]) {
        _reSendTryTimes = 0;
        if (self.delegate && [self.delegate respondsToSelector:@selector(didReceiveRequest:)]) {
            [self.delegate didReceiveRequest:(TFTPReadRequest *)packet];
        }
    }
    else if ([packet isKindOfClass:[TFTPWriteRequest class]])
    {

    }
    else if ([packet isKindOfClass:[TFTPData class]])
    {

    }
    else if ([packet isKindOfClass:[TFTPAcknowledgement class]])
    {
        TFTPAcknowledgement *pack = (TFTPAcknowledgement *)packet;
        if (self.currentBlock % 256 == pack.block % 256) {
            NSLog(@"当前收到第%lld的确认",self.currentBlock);
             self.currentBlock ++;
            _reSendTryTimes = 0;
        }
        [self sendData];
        
        //发送成功 会比之前多发送2个  其中一个是结束包 空包  另一个是发着玩的  多发的 也是空的  循环没控制它不发 就发了 反正对方接收第一个空包时已经关闭了接收
        if (self.currentBlock - self.totalBlock >= 1) {
            NSLog(@"终于传完了");
            
            self.currentBlock = 1;
            self.connectHost = nil;
            NSLog(@"重置%lld",self.currentBlock);
        
            if (self.delegate && [self.delegate respondsToSelector:@selector(didFinishSendWithPath:)]) {
                [self.delegate didFinishSendWithPath:_filePath];
            }

            return NO;
        }
    }
    else if ([packet isKindOfClass:[TFTPError class]])
    {
        TFTPError *pack = (TFTPError *)packet;
        if (self.delegate && [self.delegate respondsToSelector:@selector(didFailSend:)]) {
            [self.delegate didFailSend:pack.message];
        }
    }
    return YES;
}
-(void)sendData
{
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    
    NSData *fileData = [self GetFileData];
    if (fileData.length == BLOCKSIZE) {
        
        //尝试发送次数少于最大尝试时才会计时
        if (_reSendTryTimes < PKT_MAX_RXMT) {
            _timer =  [NSTimer timerWithTimeInterval:PKT_RCV_TIMEOUT target:self selector:@selector(reSendData) userInfo:nil repeats:NO];
            [[NSRunLoop mainRunLoop]addTimer:_timer forMode:NSDefaultRunLoopMode];
        }
        else
        {
            NSLog(@"尝试%d次还未成功 发送失败",_reSendTryTimes);
            if (self.delegate && [self.delegate respondsToSelector:@selector(didFailSend:)]) {
                [self.delegate didFailSend:@"多次尝试发送失败"];
            }
            return;
        }
    }

    if (self.currentBlock <= self.totalBlock) {
        NSData *sendData = [TFTPData blackData:fileData block:_currentBlock];
        [_udpSocket sendData:sendData toHost:self.connectHost port:self.connectPort withTimeout:1 tag:1000];
    }
    else
    {
        
        NSData *sendData = [TFTPData blackData:[[NSData alloc]init] block:_currentBlock];
        [_udpSocket sendData:sendData toHost:self.connectHost port:self.connectPort withTimeout:1 tag:1000];
    }
    
    
    
    NSLog(@"总共%lld个包，发送第%lld个",self.totalBlock,self.currentBlock);
    
    //发送成功 会比之前多发送2个  其中一个是结束包 空包  另一个是发着玩的  多发的 也是空的  循环没控制它不发 就发了 反正对方接收第一个空包时已经关闭了接收
    if (self.currentBlock <= self.totalBlock) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(didSendBytes:totalBytes:)]) {
            [self.delegate didSendBytes:(BLOCKSIZE * (self.currentBlock - 1) + fileData.length) totalBytes:self.fileData.length];
        }
    }
}
-(void)reSendData
{
     _reSendTryTimes ++;
    NSLog(@"重新发送第%lld个包",self.currentBlock);
    [self sendData];
}
-(NSData *)GetFileData
{
    [self.handler seekToFileOffset:BLOCKSIZE * (self.currentBlock - 1)];
    NSData *data = [self.handler readDataOfLength:BLOCKSIZE];
    return data;
}
-(void)setFilePath:(NSString *)path
{
    _filePath = path;
    
    if (_handler) {
        [_handler closeFile];
        _handler  = nil;
    }
    
    _handler = [NSFileHandle fileHandleForReadingAtPath:path];
    
    self.fileData = [_handler readDataToEndOfFile];
    
    self.totalBlock = (long long)self.fileData.length % BLOCKSIZE == 0 ? ((long long)self.fileData.length / BLOCKSIZE) : ((long long)self.fileData.length / BLOCKSIZE + 1);
    
    self.currentBlock = 1;
    
}
-(void)startServer
{
    [_udpSocket beginReceiving:nil];
}
-(void)closeServer
{
    if (_udpSocket && _udpSocket.isConnected) {
        [_udpSocket close];
    }

    _reSendTryTimes = 0;
    _currentBlock = 1;
    self.connectHost = nil;
    
    [self closeFile];
}
-(void)closeFile
{
    if (_handler) {
        [_handler closeFile];
    }
}
-(void)dealloc
{
    NSLog(@"tftpServer😆销毁了");
}
@end
