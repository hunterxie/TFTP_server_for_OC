//
//  TFTPServer.h
//  TFTPdemo
//
//  Created by xll on 2017/11/1.
//  Copyright © 2017年 xll. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GCDAsyncUdpSocket.h>
#import "TFTPPacket.h"

@protocol TFTPServerDelegate

@required

//这个是收到请求包的时候回调 这个必须写 因为他决定获取那个文件 然后需要用户在回调中设置下载的文件路径 然后开启发送data
-(void)didReceiveRequest:(TFTPReadRequest *)packet;

@optional

//已经发送了多少字节  总共多少字节
-(void)didSendBytes:(long long)hasSendBytes totalBytes:(long long)totalBytes;

//发送失败回调
-(void)didFailSend:(NSString *)error;

//成功发送一个文件后返回文件路径
-(void)didFinishSendWithPath:(NSString *)filePath;
@end


@interface TFTPServer : NSObject

@property(nonatomic,strong)GCDAsyncUdpSocket *udpSocket;

//文件handler
@property(nonatomic,strong)NSFileHandle *handler;

//初始化server
-(instancetype)initServerWithPort:(uint16_t)port delegate:(NSObject<TFTPServerDelegate> *)delegate;

//设置将要发送文件的路径  
-(void)setFilePath:(NSString *)path;

//开启server
-(void)startServer ;

/**
 发送数据  在发送之前必须设置要发送文件路径  也就是需要调用setFilePath
 */
-(void)sendData;
/**
 关闭服务
 */
-(void)closeServer;

@end
