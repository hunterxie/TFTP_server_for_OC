//
//  ViewController.m
//  TFTPdemo
//
//  Created by xll on 2017/10/27.
//  Copyright © 2017年 xll. All rights reserved.
//

#import "ViewController.h"
#import "TFTPPacket.h"
#import "TFTPServer.h"

@interface ViewController ()<TFTPServerDelegate>
{
    GCDAsyncUdpSocket *udpSocket;
    
}

@property(nonatomic,strong)TFTPServer *tftpServer;
@end

@implementation ViewController

-(void)didReceiveRequest:(TFTPReadRequest *)packet
{
    if ([packet.name hasPrefix:@"b.config"]) {
        
        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        documentsPath  = [NSString stringWithFormat:@"%@/music",documentsPath];
        
        if (![[NSFileManager defaultManager]fileExistsAtPath:documentsPath]) {
            [[NSFileManager defaultManager]createDirectoryAtPath:documentsPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        NSString *filePath = [NSString stringWithFormat:@"%@/b.config",documentsPath];
    
        [self.tftpServer setFilePath:filePath];
        [self.tftpServer sendData];
    }
    else if ([packet.name hasPrefix:@"十七岁__刘德华.mp3"])
    {
        NSString *path =  [[NSBundle mainBundle]pathForResource:@"liudehua" ofType:@"mp3"];
        [self.tftpServer setFilePath:path];
        [self.tftpServer sendData];
    }
    else if ([packet.name hasPrefix:@"平凡之路__朴树.mp3"])
    {
        NSString *path =  [[NSBundle mainBundle]pathForResource:@"pingfan" ofType:@"mp3"];
        [self.tftpServer setFilePath:path];
        [self.tftpServer sendData];
    }
}
-(void)didSendBytes:(long long)hasSendBytes totalBytes:(long long)totalBytes
{
    NSLog(@"---->%lld--%lld",hasSendBytes,totalBytes);
}
-(void)didFailSend:(NSString *)error
{
    NSLog(@"something wrong occur");
}
-(void)didFinishSendWithPath:(NSString *)filePath
{
    NSLog(@"happy ending");
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSMutableData *data = [[NSMutableData alloc]init];
    
    NSString *configName = @"十七岁__刘德华.mp3";
    NSData *configData = [configName dataUsingEncoding:NSUTF8StringEncoding];
    
    
    
    uint8_t *bytes = malloc(2);
    bytes[0] = 2;
    bytes[1] = configData.length;
    [data appendBytes:bytes length:2];
    [data appendData:configData];
    
    NSString *otherName = @"平凡之路__朴树.mp3";
    NSData *otherData = [otherName dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t *otherBytes = malloc(1);
    otherBytes[0] = otherData.length;
    [data appendBytes:otherBytes length:1];
    [data appendData:otherData];
    
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    documentsPath  = [NSString stringWithFormat:@"%@/music",documentsPath];
    
    if (![[NSFileManager defaultManager]fileExistsAtPath:documentsPath]) {
        [[NSFileManager defaultManager]createDirectoryAtPath:documentsPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *filePath = [NSString stringWithFormat:@"%@/b.config",documentsPath];
    BOOL isOK =  [data writeToFile:filePath atomically:YES];
    
    
    self.tftpServer = [[TFTPServer alloc]initServerWithPort:8085 delegate:self];
    [self.tftpServer startServer];
    
    
    //请到手机端设置去查看ip地址
  
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
