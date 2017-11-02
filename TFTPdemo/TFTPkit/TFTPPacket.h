//
//  TFTPPacket.h
//  TFTPdemo
//
//  Created by xll on 2017/10/27.
//  Copyright © 2017年 xll. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(UInt8, TFTPOperation) {
    readRequest = 1,
    writeRequest = 2,
    dataOperation = 3,
    acknowledgement = 4,
    errorOperation = 5,
};

typedef NS_ENUM(UInt8, TFTPTransmissionMode) {
    Octet = 1,
    Mail = 2,
    NetAscii = 3,
};


@interface TFTPPacket : NSObject

@property(nonatomic,assign)TFTPOperation opcode;

/**
 将packers转化为data

 @return data
 */
-(NSData *)serialize;

/**
 获取类型code

 @return code
 */
-(short)serializeOpCode;

/**
 获取packet的前两个字节   表明类型的字节

 @return byte
 */
-(Byte *)GetSerializeOpCode;

/**
 根据data返回不同类型的packet模型

 @param data data
 @return packet
 */
+(TFTPPacket *)deserializeFrom:(NSData *)data;

/**
 根据 长整型num  返回相对应的 两个字节byte

 @param num num
 @return byte
 */
+(uint8_t *)GetByteFrom:(long long)num;

@end


/**
 读 packet
 */
@interface TFTPReadRequest : TFTPPacket
@property(nonatomic,copy)NSString *name;
@property(nonatomic,assign)TFTPTransmissionMode modeStr;
@property(nonatomic,copy)NSString *mode;

@end


/**
 写packet
 */
@interface TFTPWriteRequest : TFTPPacket
@property(nonatomic,copy)NSString *name;
@property(nonatomic,assign)TFTPTransmissionMode modeStr;
@property(nonatomic,copy)NSString *mode;

@end


/**
 传输的data packet
 */
@interface TFTPData :TFTPPacket

@property(nonatomic,assign)UInt8 block ;

@property(nonatomic,strong)NSData *data;


/**
将发送块的data 拼接类型和块number

 @param blockData 文件data
 @param block 块number
 @return 最终发送的data
 */
+(NSData *)blackData:(NSData *)blockData block:(long long)block;

@end


/**
 确认包
 */
@interface TFTPAcknowledgement :TFTPPacket

/**
 块number
 */
@property(nonatomic,assign)UInt8 block ;

@end


/**
 error packet
 */
@interface TFTPError :TFTPPacket
@property(nonatomic,assign)UInt8 code;
@property(nonatomic,copy)NSString *message;
@end
