//
//  TFTPClient.m
//  TFTPdemo
//
//  Created by xll on 2017/10/27.
//  Copyright © 2017年 xll. All rights reserved.
//

#import "TFTPClient.h"
#import <GCDAsyncUdpSocket.h>


@interface TFTPClient()<GCDAsyncUdpSocketDelegate>
@property(nonatomic,copy)NSString *host;
@property(nonatomic,assign)UInt16 port;
@property(nonatomic,weak)id<TFTPClientDelegate>delegate;

@property(nonatomic)dispatch_queue_t delegateQueue;

@property(nonatomic,strong)NSData *address;

@property(nonatomic,strong)GCDAsyncUdpSocket *socket;

@property(nonatomic,strong)NSFileHandle *fileHandle;
@property(nonatomic,copy)NSString *name;
@property(nonatomic,copy)NSString *path;
@property(nonatomic,assign)TFTPTransmissionMode mode;

@property(nonatomic)UInt64 fileSize;


@property(nonatomic,assign)BOOL isRunning;

@end


@implementation TFTPClient


-(instancetype)initWithHost:(NSString *)host prot:(UInt16)port delegate:(id <TFTPClientDelegate>)delegate delegateQueue:(dispatch_queue_t)queue
{
    self = [super init];
    if(self)
    {
        _host = host;
        _port = port;
        _delegate = delegate;
        _delegateQueue = queue;
    }
    return self;
}
-(void)sendFile:(NSString *)path name:(NSString *)name model:(TFTPTransmissionMode)mode
{
    if (_isRunning) {
        NSLog(@"Client is already running");
        return;
    }
    NSString *modeStr;
    if (mode == TFTPTransmissionOctet) {
        modeStr = @"octet";
    }
    
    _isRunning = YES;
    _path = path;
    _name = name;
    _mode = mode;
    self.fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
    
    NSError *error ;
    
    NSDictionary *attr = [[NSFileManager defaultManager]attributesOfItemAtPath:path error:&error];

    if (!error) {
        if (attr) {
            _fileSize = attr.fileSize;
        }
    }
    [self connect];
}
-(void)connect
{
    _socket = [[GCDAsyncUdpSocket alloc]initWithDelegate:self delegateQueue:_delegateQueue];
    [_socket bindToPort:_port error:nil];
    [_socket beginReceiving:nil];
    [_socket setReceiveFilter:^BOOL(NSData * _Nonnull data, NSData * _Nonnull address, id  _Nullable __autoreleasing * _Nonnull context) {
        NSString *str = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        NSString *addressStr  = [[NSString alloc]initWithData:address encoding:NSUTF8StringEncoding];
        
        NSLog(@"AAAAA---data=%@ \naddress=%@ ",str,addressStr);
        return YES;
    } withQueue:_delegateQueue];
    [self sendWriteRequest];
}
-(void)sendWriteRequest
{
    
}
-(void)cleanup
{
    [self closeSocket];
    [self closeFile];
}
-(void)closeSocket
{
    if (_socket && _socket.isConnected) {
        [_socket close];
    }
}
-(void)closeFile
{
    if (_fileHandle) {
        [_fileHandle closeFile];
    }
}
#pragma mark  GCDAsyncUdpSocketDelegate
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address
{
    
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError * _Nullable)error
{
    
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError * _Nullable)error
{
    
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address
        withFilterContext:(nullable id)filterContext
{
//    NSString *str = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
//    NSString *addressStr  = [[NSString alloc]initWithData:address encoding:NSUTF8StringEncoding];
//
//    NSLog(@"BBBBB---data=%@ \naddress=%@ \nfilter=%@",str,addressStr,filterContext);
    
}

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError  * _Nullable)error
{
    [self cleanup];
}
@end


