//
//  TFTPClient.h
//  TFTPdemo
//
//  Created by xll on 2017/10/27.
//  Copyright © 2017年 xll. All rights reserved.
//



#import <Foundation/Foundation.h>

//case Octet = "octet"
//case NetAscii = "netascii"
//case Mail = "mail"
typedef NS_ENUM(NSInteger, TFTPTransmissionMode) {
    TFTPTransmissionOctet,
    TFTPTransmissionNetAscii,
    TFTPTransmissionMail,
};

@protocol TFTPClientDelegate


@end

@interface TFTPClient : NSObject

-(instancetype)initWithHost:(NSString *)host prot:(UInt16)port delegate:(id <TFTPClientDelegate>)delegate delegateQueue:(dispatch_queue_t)queue;

-(void)sendFile:(NSString *)path name:(NSString *)name model:(TFTPTransmissionMode)mode;

@end


//没时间写了  活太多
