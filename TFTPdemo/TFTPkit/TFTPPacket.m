//
//  TFTPPacket.m
//  TFTPdemo
//
//  Created by xll on 2017/10/27.
//  Copyright © 2017年 xll. All rights reserved.
//

#import "TFTPPacket.h"

@implementation TFTPPacket


-(NSData *)serialize
{
    NSMutableData *data = [[NSMutableData alloc]initWithCapacity:0];

    return data;
}
-(uint8_t *)GetSerializeOpCode
{
    short num = [self GetRawValueFrom:self.opcode];
    uint8_t * bytes  = malloc(sizeof(char) * 2);
    bytes[1]  =  (char)(num & 0xff);
    bytes[0]  =  (char)((num >> 8) & 0xff);
    return bytes;
}
+(uint8_t *)GetByteFrom:(long long)num
{
    uint8_t * bytes  = malloc(sizeof(char) * 2);
    bytes[1]  =  (char)(num & 0xff);
    bytes[0]  =  (char)((num >> 8) & 0xff);
    return bytes;
}
-(short)serializeOpCode
{
    return [self GetRawValueFrom:self.opcode];
}
-(short)GetRawValueFrom:(TFTPOperation)operation
{
    switch (operation) {
        case readRequest:
        {
            return 1;
        }
            break;
        case writeRequest:
        {
            return 2;
        }
            break;
        case dataOperation:
        {
            return 3;
        }
            break;
        case acknowledgement:
        {
            return 4;
        }
            break;
        case errorOperation:
        {
            return 5;
        }
            break;
        default:
        {
            return 0;
        }
            break;
    }
}
+(TFTPPacket *)deserializeFrom:(NSData *)data
{
    Byte *bytes = (Byte *)[data bytes];
    short code = (bytes[0] >> 8 & 0xff) + (bytes[1] & 0xff);
    
    if (code == 1) {
        TFTPReadRequest *packet = [[TFTPReadRequest alloc]init];
        packet.opcode =  readRequest;
        NSData *strData = [data subdataWithRange:NSMakeRange(2, data.length - 2)];
        packet.name =  [[NSString alloc]initWithData:strData encoding:NSUTF8StringEncoding];
        return packet;
    }
    else if (code == 2)
    {
        TFTPWriteRequest *packet = [[TFTPWriteRequest alloc]init];
        packet.opcode =  writeRequest;
        NSData *strData = [data subdataWithRange:NSMakeRange(2, data.length - 2)];
        packet.name =  [[NSString alloc]initWithData:strData encoding:NSUTF8StringEncoding];
        return packet;
    }
    else if (code == 3)
    {
        TFTPData *packet = [[TFTPData alloc]init];
        packet.opcode =  dataOperation;
        
        NSData *blockData = [data subdataWithRange:NSMakeRange(2, 2)];
        Byte *blockbytes = (Byte *)[blockData bytes];
        UInt8 block = (blockbytes[0] >> 8 & 0xff) + (blockbytes[1] & 0xff);
        packet.block = block;
        
        packet.data = [data subdataWithRange:NSMakeRange(4, data.length - 4)];
        return packet;
    }
    else if (code == 4)
    {
        TFTPAcknowledgement *packet = [[TFTPAcknowledgement alloc]init];
        packet.opcode =  acknowledgement;
        
        NSData *blockData = [data subdataWithRange:NSMakeRange(2, 2)];
        Byte *blockbytes = (Byte *)[blockData bytes];
        UInt8 block = (blockbytes[0] >> 8 & 0xff) + (blockbytes[1] & 0xff);
        packet.block = block;
        
        return packet;
    }
    else if (code == 5)
    {
        TFTPError *packet = [[TFTPError alloc]init];
        packet.opcode =  errorOperation;
        NSData *errorData = [data subdataWithRange:NSMakeRange(2, 2)];
        Byte *errorbytes = (Byte *)[errorData bytes];
        UInt8 error = (errorbytes[0] >> 8 & 0xff) + (errorbytes[1] & 0xff);
        packet.code = error;
        NSData *strData = [data subdataWithRange:NSMakeRange(4, data.length - 4)];
        packet.message =  [[NSString alloc]initWithData:strData encoding:NSUTF8StringEncoding];
        return packet;
    }
    return nil;
}

@end

@implementation TFTPReadRequest

-(NSData *)serialize
{
    NSMutableData *data = [[NSMutableData alloc]initWithCapacity:0];
    NSData *nameData = [self.name dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t *opcode = [self GetSerializeOpCode];
    [data appendBytes:opcode length:2];
    [data appendData:nameData];
    return data;
}

@end

@implementation TFTPWriteRequest

-(NSData *)serialize
{
    NSMutableData *data = [[NSMutableData alloc]initWithCapacity:0];
    NSData *nameData = [self.name dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t *opcode = [self GetSerializeOpCode];
    [data appendBytes:opcode length:2];
    [data appendData:nameData];
    return data;
}

@end

@implementation TFTPData

-(NSData *)serialize
{
    NSMutableData *data = [[NSMutableData alloc]initWithCapacity:0];
    uint8_t *opcode = [self GetSerializeOpCode];
    [data appendBytes:opcode length:2];
    uint8_t *blockByte = [TFTPPacket GetByteFrom:self.block];
    [data appendBytes:blockByte length:2];
    [data appendData:self.data];
    return data;
}

+(NSData *)blackData:(NSData *)blockData block:(long long)block
{
    NSMutableData *sendData = [[NSMutableData alloc]initWithCapacity:0];
    uint8_t *opcode = [TFTPPacket GetByteFrom:3];
    uint8_t *blockcode = [TFTPPacket GetByteFrom:block];
    [sendData appendBytes:opcode length:2];
    [sendData appendBytes:blockcode length:2];
    if (blockData) {
        [sendData appendData:blockData];
    }
    
    return sendData;
}
@end

@implementation TFTPAcknowledgement

-(NSData *)serialize
{
    NSMutableData *data = [[NSMutableData alloc]initWithCapacity:0];
    uint8_t *opcode = [self GetSerializeOpCode];
    [data appendBytes:opcode length:2];
    uint8_t *blockByte = [TFTPPacket GetByteFrom:self.block];
    [data appendBytes:blockByte length:2];
    return data;
}

@end

@implementation TFTPError

-(NSData *)serialize
{
    NSMutableData *data = [[NSMutableData alloc]initWithCapacity:0];
    NSData *nameData = [self.message dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t *opcode = [self GetSerializeOpCode];
    [data appendBytes:opcode length:2];
    uint8_t *errorByte = [TFTPPacket GetByteFrom:self.code];
    [data appendBytes:errorByte length:2];
    [data appendData:nameData];
    return data;
}

@end
