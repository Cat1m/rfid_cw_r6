//
//  RFIDBlutoothManager.m
//  RFID_ios
//
//  Created by chainway on 2018/4/26.
//  Copyright © 2018年 chainway. All rights reserved.
//

#import "RFIDBlutoothManager.h"
//#import "BSprogreUtil.h"
#import "AppHelper.h"
#import <UIKit/UIKit.h>

#define kFatscaleTimeOut 5.0

#define serviceUUID  @"6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define writeUUID  @"6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
#define receiveUUID  @"6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
//#define serviceUUID  @"6e400001-b5a3-f393-e0a9-e50e24dcca9e"
//#define writeUUID  @"6e400002-b5a3-f393-e0a9-e50e24dcca9e"
//#define receiveUUID  @"6e400003-b5a3-f393-e0a9-e50e24dcca9e"

#define macAddressStr @"macAddress"
#define BLE_SEND_MAX_LEN 20

#define UpdateBLE_SEND_MAX_LEN 20

@interface RFIDBlutoothManager () <CBCentralManagerDelegate,CBPeripheralDelegate>

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) NSTimer *bleScanTimer;
@property (nonatomic, strong) CBPeripheral *peripheral;

@property (nonatomic, strong) NSMutableArray *peripheralArray;
@property (nonatomic, weak) id<FatScaleBluetoothManager> managerDelegate;
@property (nonatomic, weak) id<PeripheralAddDelegate> addDelegate;

@property (nonatomic, copy) NSString *connectPeripheralCharUUID;

@property (nonatomic, strong) NSMutableArray *BLEServerDatasArray;

@property (nonatomic, strong) CBCharacteristic *myCharacteristic;
@property (nonatomic, strong) NSTimer *connectTime;//计算蓝牙连接是否超时的定时器
@property (nonatomic, strong) NSMutableArray *dataList;
@property (nonatomic, strong) NSMutableString *dataStr;
@property (nonatomic, assign) NSInteger dataCount;
@property (nonatomic, strong) NSMutableArray *uuidDataList;
@property (nonatomic, copy) NSString *temStr;
@property (nonatomic, assign) BOOL isInfo;
@property (nonatomic, assign) BOOL isName;

@end

@implementation RFIDBlutoothManager


+ (instancetype)shareManager
{
    static RFIDBlutoothManager *shareManager = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        shareManager = [[self alloc] init];
    });
    return shareManager;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self centralManager];
        self.dataCount=0;
        self.isInfo=NO;
        self.isName=NO;
        self.dataList=[[NSMutableArray alloc]init];
        self.dataSource=[[NSMutableArray alloc]init];
         self.dataSource1 = [NSMutableArray array];
         self.dataSource2 = [NSMutableArray array];
        _tagStr=[[NSMutableString alloc]init];
        _allCount=0;
         self.isgetLab=NO;
        self.countArr=[[NSMutableArray alloc]init];
         self.countArr1 = [NSMutableArray array];
         self.countArr2 = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Public methods
- (void)bleDoScan
{
    self.bleScanTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(startBleScan) userInfo:nil repeats:YES];
}

- (void)connectPeripheral:(CBPeripheral *)peripheral macAddress:(NSString *)macAddress
{
    NSArray *aa=[macAddress componentsSeparatedByString:@":"];
    NSMutableString *str=[[NSMutableString alloc]init];
    for (NSInteger i=0; i<aa.count; i++) {
        [str appendFormat:@"%@",aa[i]];
    }
    
    NSString *strr=[NSString stringWithFormat:@"%@",str];
    
    [[NSUserDefaults standardUserDefaults] setObject:strr forKey:macAddressStr];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.peripheral = peripheral;
    
    [self.centralManager connectPeripheral:peripheral options:nil];
}
- (void)cancelConnectBLE
{
    [self.centralManager cancelPeripheralConnection:self.peripheral];
}
- (void)setFatScaleBluetoothDelegate:(id<FatScaleBluetoothManager>)delegate
{
    self.managerDelegate = delegate;
}

- (void)setPeripheralAddDelegate:(id<PeripheralAddDelegate>)delegate
{
    self.addDelegate = delegate;
}



- (Byte )getBye8:(Byte[])data
{
    Byte byte8 = data[2] + data[3] + data[4] + data[5] +data[6];
    byte8 = (unsigned char) ( byte8 & 0x00ff);
    return byte8;
}

//获取固件版本号
-(void)getFirmwareVersion2
{
     NSData *data = [BluetoothUtil getFirmwareVersion];
     [self sendDataToBle:data];
}
//获取电池电量
-(void)getBatteryLevel
{
     self.isGetBattery = YES;
    NSData *data=[BluetoothUtil getBatteryLevel];
    [self sendDataToBle:data];
    
}
//获取设备当前温度
-(void)getServiceTemperature
{
     self.isTemperature = YES;
     NSData *data=[BluetoothUtil getServiceTemperature];
     [self sendDataToBle:data];
}
//开启2D扫描
-(void)start2DScan
{
     self.isCodeLab = YES;
     NSData *data=[BluetoothUtil start2DScan];
     [self sendDataToBle:data];
     
}

//获取硬件版本号
-(void)getHardwareVersion
{
     self.isGetVerson = YES;
     NSData *data=[BluetoothUtil getHardwareVersion];
     [self sendDataToBle:data];
     
}
//获取固件版本号
-(void)getFirmwareVersion
{
     self.isGetVerson = YES;
     NSData *data = [BluetoothUtil getFirmwareVersion];
     [self sendDataToBle:data];
}
//获取设备ID
-(void)getServiceID
{
     NSData *data = [BluetoothUtil getServiceID];
     [self sendDataToBle:data];
}
//软件复位
-(void)softwareReset
{
     NSData *data = [BluetoothUtil softwareReset];
     [self sendDataToBle:data];
}
//开启蜂鸣器
-(void)setOpenBuzzer
{
     self.isOpenBuzzer = YES;
     NSData *data = [BluetoothUtil openBuzzer];
     [self sendDataToBle:data];
}
//关闭蜂鸣器
-(void)setCloseBuzzer
{
     self.isCloseBuzzer  = YES;
     NSData *data = [BluetoothUtil closeBuzzer];
     [self sendDataToBle:data];
}


//设置标签读取格式
-(void)setEpcTidUserWithAddressStr:(NSString *)addressStr length:(NSString *)lengthStr epcStr:(NSString *)epcStr
{
     self.isSetTag = YES;
     NSData *data = [BluetoothUtil setEpcTidUserWithAddressStr:addressStr length:lengthStr EPCStr:epcStr];
     NSLog(@"data==%@",data);
     [self sendDataToBle:data];
}
//获取标签读取格式
-(void)getEpcTidUser
{
     self.isGetTag = YES;
     NSData *data = [BluetoothUtil getEpcTidUser];
     NSLog(@"data==%@",data);
     [self sendDataToBle:data];
}



//设置发射功率
-(void)setLaunchPowerWithstatus:(NSString *)status antenna:(NSString *)antenna readStr:(NSString *)readStr writeStr:(NSString *)writeStr
{
     self.isSetEmissionPower = YES;
     NSData *data = [BluetoothUtil setLaunchPowerWithstatus:status antenna:antenna readStr:readStr writeStr:writeStr];
     [self sendDataToBle:data];
     
}
//获取当前发射功率
-(void)getLaunchPower
{
     self.isGetEmissionPower = YES;
     NSData *data = [BluetoothUtil getLaunchPower];
     [self sendDataToBle:data];
     
}
//跳频设置
-(void)detailChancelSettingWithstring:(NSString *)str
{
     NSData *data = [BluetoothUtil detailChancelSettingWithstring:str];
     [self sendDataToBle:data];
}
//获取当前跳频设置状态
-(void)getdetailChancelStatus
{
     NSData *data = [BluetoothUtil getdetailChancelStatus];
     [self sendDataToBle:data];
}

//区域设置
-(void)setRegionWithsaveStr:(NSString *)saveStr regionStr:(NSString *)regionStr
{
     NSData *data = [BluetoothUtil setRegionWithsaveStr:saveStr regionStr:regionStr];
     [self sendDataToBle:data];
}
//获取区域设置
-(void)getRegion
{
     NSData *data = [BluetoothUtil getRegion];
     [self sendDataToBle:data];
}

//单次盘存标签
-(void)singleSaveLabel
{
     self.isSingleSaveLable  = YES;
     NSData *data = [BluetoothUtil singleSaveLabel];
     [self sendDataToBle:data];
}

//连续盘存标签
-(void)continuitySaveLabelWithCount:(NSString *)count
{
     NSData *data = [BluetoothUtil continuitySaveLabelWithCount:count];
     [self sendDataToBle:data];
}

//停止连续盘存标签
-(void)StopcontinuitySaveLabel
{
     NSData *data = [BluetoothUtil StopcontinuitySaveLabel];
     [self sendDataToBle:data];
}
//读标签数据区
-(void)readLabelMessageWithPassword:(NSString *)password MMBstr:(NSString *)MMBstr MSAstr:(NSString *)MSAstr MDLstr:(NSString *)MDLstr MDdata:(NSString *)MDdata MBstr:(NSString *)MBstr SAstr:(NSString *)SAstr DLstr:(NSString *)DLstr isfilter:(BOOL)isfilter
{
          NSData *data = [BluetoothUtil readLabelMessageWithPassword:password MMBstr:MMBstr MSAstr:MSAstr MDLstr:MDLstr MDdata:MDdata MBstr:MBstr SAstr:SAstr DLstr:DLstr isfilter:isfilter];
          NSLog(@"data===%@",data);
          for (int i = 0; i < [data length]; i += BLE_SEND_MAX_LEN) {
               // 预加 最大包长度，如果依然小于总数据长度，可以取最大包数据大小
               if ((i + BLE_SEND_MAX_LEN) < [data length]) {
                    NSString *rangeStr = [NSString stringWithFormat:@"%i,%i", i, BLE_SEND_MAX_LEN];
                    NSData *subData = [data subdataWithRange:NSRangeFromString(rangeStr)];
                    NSLog(@"%@",subData);
                    [self sendDataToBle:subData];
                    //根据接收模块的处理能力做相应延时
                    usleep(80 * 1000);
               }
               else {
                    NSString *rangeStr = [NSString stringWithFormat:@"%i,%i", i, (int)([data length] - i)];
                    NSData *subData = [data subdataWithRange:NSRangeFromString(rangeStr)];
                    [self sendDataToBle:subData];
                    usleep(80 * 1000);
               }
          }
}
//写标签数据区
-(void)writeLabelMessageWithPassword:(NSString *)password MMBstr:(NSString *)MMBstr MSAstr:(NSString *)MSAstr MDLstr:(NSString *)MDLstr MDdata:(NSString *)MDdata MBstr:(NSString *)MBstr SAstr:(NSString *)SAstr DLstr:(NSString *)DLstr writeData:(NSString *)writeData isfilter:(BOOL)isfilter
{
          NSData *data = [BluetoothUtil writeLabelMessageWithPassword:password MMBstr:MMBstr MSAstr:MSAstr MDLstr:MDLstr MDdata:MDdata MBstr:MBstr SAstr:SAstr DLstr:DLstr writeData:writeData isfilter:isfilter];
       
          for (int i = 0; i < [data length]; i += BLE_SEND_MAX_LEN) {
               // 预加 最大包长度，如果依然小于总数据长度，可以取最大包数据大小
               if ((i + BLE_SEND_MAX_LEN) < [data length]) {
                    NSString *rangeStr = [NSString stringWithFormat:@"%i,%i", i, BLE_SEND_MAX_LEN];
                    NSData *subData = [data subdataWithRange:NSRangeFromString(rangeStr)];
                     NSLog(@"subData==%@",subData);
                    [self sendDataToBle:subData];
                    //根据接收模块的处理能力做相应延时
                    usleep(80 * 1000);
               }
               else {
                    NSString *rangeStr = [NSString stringWithFormat:@"%i,%i", i, (int)([data length] - i)];
                    NSData *subData = [data subdataWithRange:NSRangeFromString(rangeStr)];
                    NSLog(@"subData==%@",subData);
                    [self sendDataToBle:subData];
                    usleep(80 * 1000);
               }
          }
}
//Lock标签
-(void)lockLabelWithPassword:(NSString *)password MMBstr:(NSString *)MMBstr MSAstr:(NSString *)MSAstr MDLstr:(NSString *)MDLstr MDdata:(NSString *)MDdata ldStr:(NSString *)ldStr isfilter:(BOOL)isfilter
{
     NSData *data=[BluetoothUtil lockLabelWithPassword:password MMBstr:MMBstr MSAstr:MSAstr MDLstr:MDLstr MDdata:MDdata ldStr:ldStr isfilter:isfilter];
     NSLog(@"data===%@",data);
     for (int i = 0; i < [data length]; i += BLE_SEND_MAX_LEN) {
          // 预加 最大包长度，如果依然小于总数据长度，可以取最大包数据大小
          if ((i + BLE_SEND_MAX_LEN) < [data length]) {
               NSString *rangeStr = [NSString stringWithFormat:@"%i,%i", i, BLE_SEND_MAX_LEN];
               NSData *subData = [data subdataWithRange:NSRangeFromString(rangeStr)];
               NSLog(@"%@",subData);
               [self sendDataToBle:subData];
               //根据接收模块的处理能力做相应延时
               usleep(80 * 1000);
          }
          else {
               NSString *rangeStr = [NSString stringWithFormat:@"%i,%i", i, (int)([data length] - i)];
               NSData *subData = [data subdataWithRange:NSRangeFromString(rangeStr)];
               [self sendDataToBle:subData];
               usleep(80 * 1000);
          }
     }
}//
//kill标签。
-(void)killLabelWithPassword:(NSString *)password MMBstr:(NSString *)MMBstr MSAstr:(NSString *)MSAstr MDLstr:(NSString *)MDLstr MDdata:(NSString *)MDdata isfilter:(BOOL)isfilter
{
     NSData *data = [BluetoothUtil killLabelWithPassword:password MMBstr:MMBstr MSAstr:MSAstr MDLstr:MDLstr MDdata:MDdata isfilter:isfilter];
     NSLog(@"data===%@",data);
     for (int i = 0; i < [data length]; i += BLE_SEND_MAX_LEN) {
          // 预加 最大包长度，如果依然小于总数据长度，可以取最大包数据大小
          if ((i + BLE_SEND_MAX_LEN) < [data length]) {
               NSString *rangeStr = [NSString stringWithFormat:@"%i,%i", i, BLE_SEND_MAX_LEN];
               NSData *subData = [data subdataWithRange:NSRangeFromString(rangeStr)];
               NSLog(@"%@",subData);
               [self sendDataToBle:subData];
               //根据接收模块的处理能力做相应延时
               usleep(80 * 1000);
          }
          else {
               NSString *rangeStr = [NSString stringWithFormat:@"%i,%i", i, (int)([data length] - i)];
               NSData *subData = [data subdataWithRange:NSRangeFromString(rangeStr)];
               [self sendDataToBle:subData];
               usleep(80 * 1000);
          }
     }
}
//获取标签数据
-(void)getLabMessage
{
     NSData *data = [BluetoothUtil getLabMessage];
     [self sendDataToBle:data];
}
//设置密钥
-(void)setSM4PassWordWithmodel:(NSString *)model password:(NSString *)password originPass:(NSString *)originPass
{
      NSData *data = [BluetoothUtil setSM4PassWordWithmodel:model password:password originPass:originPass];
     
     for (int i = 0; i < [data length]; i += BLE_SEND_MAX_LEN) {
          // 预加 最大包长度，如果依然小于总数据长度，可以取最大包数据大小
          if ((i + BLE_SEND_MAX_LEN) < [data length]) {
               NSString *rangeStr = [NSString stringWithFormat:@"%i,%i", i, BLE_SEND_MAX_LEN];
               NSData *subData = [data subdataWithRange:NSRangeFromString(rangeStr)];
               NSLog(@"%@",subData);
                [self sendDataToBle:subData];
               //根据接收模块的处理能力做相应延时
               usleep(80 * 1000);
               
          }
          else {
               NSString *rangeStr = [NSString stringWithFormat:@"%i,%i", i, (int)([data length] - i)];
               NSData *subData = [data subdataWithRange:NSRangeFromString(rangeStr)];
                [self sendDataToBle:subData];
               usleep(80 * 1000);
          }
     }
}
//获取密钥
-(void)getSM4PassWord
{
     NSData *data = [BluetoothUtil getSM4PassWord];
     [self sendDataToBle:data];
}
//SM4数据加密
-(void)encryptionPassWordwithmessage:(NSString *)message
{
     NSData *data = [BluetoothUtil encryptionPassWordwithmessage:message];
     NSLog(@"data===%@",data);
     for (int i = 0; i < [data length]; i += BLE_SEND_MAX_LEN) {
          // 预加 最大包长度，如果依然小于总数据长度，可以取最大包数据大小
          if ((i + BLE_SEND_MAX_LEN) < [data length]) {
               NSString *rangeStr = [NSString stringWithFormat:@"%i,%i", i, BLE_SEND_MAX_LEN];
               NSData *subData = [data subdataWithRange:NSRangeFromString(rangeStr)];
               NSLog(@"%@",subData);
               [self sendDataToBle:subData];
               //根据接收模块的处理能力做相应延时
               usleep(80 * 1000);
          }
          else {
               NSString *rangeStr = [NSString stringWithFormat:@"%i,%i", i, (int)([data length] - i)];
               NSData *subData = [data subdataWithRange:NSRangeFromString(rangeStr)];
               [self sendDataToBle:subData];
               usleep(80 * 1000);
          }
     }
}
//SM4数据解密
-(void)decryptPassWordwithmessage:(NSString *)message
{
     NSData *data = [BluetoothUtil decryptPassWordwithmessage:message];
     for (int i = 0; i < [data length]; i += BLE_SEND_MAX_LEN) {
          // 预加 最大包长度，如果依然小于总数据长度，可以取最大包数据大小
          if ((i + BLE_SEND_MAX_LEN) < [data length]) {
               NSString *rangeStr = [NSString stringWithFormat:@"%i,%i", i, BLE_SEND_MAX_LEN];
               NSData *subData = [data subdataWithRange:NSRangeFromString(rangeStr)];
               NSLog(@"%@",subData);
               [self sendDataToBle:subData];
               //根据接收模块的处理能力做相应延时
               usleep(80 * 1000);
          }
          else {
               NSString *rangeStr = [NSString stringWithFormat:@"%i,%i", i, (int)([data length] - i)];
               NSData *subData = [data subdataWithRange:NSRangeFromString(rangeStr)];
               [self sendDataToBle:subData];
               usleep(80 * 1000);
          }
     }
}
//USER加密
-(void)encryptionUSERWithaddress:(NSString *)address lengthStr:(NSString *)lengthStr dataStr:(NSString *)dataStr
{
     NSData *data = [BluetoothUtil encryptionUSERWithaddress:address lengthStr:lengthStr dataStr:dataStr];
     NSLog(@"data===%@",data);
     for (int i = 0; i < [data length]; i += BLE_SEND_MAX_LEN) {
          // 预加 最大包长度，如果依然小于总数据长度，可以取最大包数据大小
          if ((i + BLE_SEND_MAX_LEN) < [data length]) {
               NSString *rangeStr = [NSString stringWithFormat:@"%i,%i", i, BLE_SEND_MAX_LEN];
               NSData *subData = [data subdataWithRange:NSRangeFromString(rangeStr)];
              // NSLog(@"%@",subData);
               [self sendDataToBle:subData];
               //根据接收模块的处理能力做相应延时
               usleep(80 * 1000);
          }
          else {
               NSString *rangeStr = [NSString stringWithFormat:@"%i,%i", i, (int)([data length] - i)];
               NSData *subData = [data subdataWithRange:NSRangeFromString(rangeStr)];
               [self sendDataToBle:subData];
               usleep(80 * 1000);
          }
     }
}
//USER解密
-(void)decryptUSERWithaddress:(NSString *)address lengthStr:(NSString *)lengthStr
{
     NSData *data = [BluetoothUtil decryptUSERWithaddress:address lengthStr:lengthStr];
     [self sendDataToBle:data];
}
//进入升级模式
-(void)enterUpgradeMode
{
     NSData *data=[BluetoothUtil enterUpgradeMode];
     [self sendDataToBle:data];
}
//进入升级接收数据
-(void)enterUpgradeAcceptData
{
     NSData *data=[BluetoothUtil enterUpgradeAcceptData];
     [self sendDataToBle:data];
}

//进入升级发送数据
-(void)enterUpgradeSendtDataWith:(NSString *)dataStr
{
     NSData *data=[BluetoothUtil enterUpgradeSendtDataWith:dataStr];
     NSLog(@"data===%@",data);
     for (int i = 0; i < [data length]; i += BLE_SEND_MAX_LEN) {
          // 预加 最大包长度，如果依然小于总数据长度，可以取最大包数据大小
          if ((i + BLE_SEND_MAX_LEN) < [data length]) {
               NSString *rangeStr = [NSString stringWithFormat:@"%i,%i", i, BLE_SEND_MAX_LEN];
               NSData *subData = [data subdataWithRange:NSRangeFromString(rangeStr)];
               // NSLog(@"%@",subData);
               [self sendDataToBle:subData];
               //根据接收模块的处理能力做相应延时
               usleep(80 * 1000);
          }
          else {
               NSString *rangeStr = [NSString stringWithFormat:@"%i,%i", i, (int)([data length] - i)];
               NSData *subData = [data subdataWithRange:NSRangeFromString(rangeStr)];
               [self sendDataToBle:subData];
               usleep(80 * 1000);
          }
     }
}
//发送升级数据
-(void)sendtUpgradeDataWith:(NSData *)dataStr
{
     //
     NSData *data = dataStr;
     NSLog(@"data===%@",data);
     for (int i = 0; i < [data length]; i += UpdateBLE_SEND_MAX_LEN) {
          // 预加 最大包长度，如果依然小于总数据长度，可以取最大包数据大小
          if ((i + UpdateBLE_SEND_MAX_LEN) < [data length]) {
               NSString *rangeStr = [NSString stringWithFormat:@"%i,%i", i, UpdateBLE_SEND_MAX_LEN];
               NSData *subData = [data subdataWithRange:NSRangeFromString(rangeStr)];
               // NSLog(@"%@",subData);
               [self sendDataToBle:subData];
               //根据接收模块的处理能力做相应延时
               usleep(80 * 1000);
          }
          else {
               NSString *rangeStr = [NSString stringWithFormat:@"%i,%i", i, (int)([data length] - i)];
               NSData *subData = [data subdataWithRange:NSRangeFromString(rangeStr)];
               [self sendDataToBle:subData];
               usleep(80 * 1000);
          }
     }
}
//退出升级模式
-(void)exitUpgradeMode
{
     NSData *data=[BluetoothUtil exitUpgradeMode];
     NSLog(@"data===%@",data);
     [self sendDataToBle:data];
}

#pragma mark - Private Methods
- (void)startBleScan
{
    if (self.centralManager.state == CBCentralManagerStatePoweredOff)
    {
        self.connectDevice = NO;
        if ([self.managerDelegate respondsToSelector:@selector(connectBluetoothFailWithMessage:)])
        {
            [self.managerDelegate connectBluetoothFailWithMessage:[self centralManagerStateDescribe:CBCentralManagerStatePoweredOff]];
        }
        return;
    }
    if (_connectTime == nil)
    {
        //创建连接制定设备的定时器
        _connectTime = [NSTimer scheduledTimerWithTimeInterval:kFatscaleTimeOut target:self selector:@selector(connectTimeroutEvent) userInfo:nil repeats:NO];
    }
    self.uuidDataList=[[NSMutableArray alloc]init];
    [self.centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @ YES}];
}
- (void)connectTimeroutEvent
{
     
    [_connectTime invalidate];
    _connectTime = nil;
    [self stopBleScan];
    [self.centralManager stopScan];
    [self.managerDelegate receiveDataWithBLEmodel:nil result:@"1"];
     
}

- (void)stopBleScan
{
    [self.bleScanTimer invalidate];
}

- (void)closeBleAndDisconnect
{
    [self stopBleScan];
    [self.centralManager stopScan];
    if (self.peripheral) {
        [self.centralManager cancelPeripheralConnection:self.peripheral];
    }
}
//Nordic_UART_CW HotWaterBottle
- (void)sendDataToBle:(NSData *)data
{
    [self.peripheral writeValue:data forCharacteristic:self.myCharacteristic type:CBCharacteristicWriteWithoutResponse];
}


#pragma maek - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state != CBCentralManagerStatePoweredOn)
    {
        if ([self.managerDelegate respondsToSelector:@selector(connectBluetoothFailWithMessage:)])
        {
            if (central.state == CBCentralManagerStatePoweredOff)
            {
                self.connectDevice = NO;
                [self.managerDelegate connectBluetoothFailWithMessage:[self centralManagerStateDescribe:CBCentralManagerStatePoweredOff]];
            }
        }
        
    }
    
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            NSLog(@"CBCentralManagerStatePoweredOn");
            break;
        case CBCentralManagerStatePoweredOff:
            NSLog(@"蓝牙断开：CBCentralManagerStatePoweredOff");
            break;
        default:
            break;
    }
}

#pragma mark - 扫描到设备
- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    NSData *manufacturerData = [advertisementData valueForKeyPath:CBAdvertisementDataManufacturerDataKey];
    
    if (advertisementData.description.length > 0)
    {
        NSLog(@"/-------广播数据advertisementData:%@--------",advertisementData.description);
        NSLog(@"-------外设peripheral:%@--------/",peripheral.description);
        NSLog(@"peripheral.services==%@",peripheral.identifier.UUIDString);
        NSLog(@"RSSI==%@",RSSI);
    }
    
    NSString *bindString = @"";
    NSString *str = @"";
    if (manufacturerData.length>=8) {
        NSData *subData = [manufacturerData subdataWithRange:NSMakeRange(manufacturerData.length-8, 8)];
        bindString = subData.description;
        str = [self getVisiableIDUUID:bindString];
        NSLog(@" GG == %@ == GG",str);
        
    }
    
    NSString *typeStr=@"1";
    for (NSString *uuidStr in self.uuidDataList) {
        if ([peripheral.identifier.UUIDString isEqualToString:uuidStr]) {
            typeStr=@"2";
        }
    }
    if ([typeStr isEqualToString:@"1"]) {
        [self.uuidDataList addObject:peripheral.identifier.UUIDString];
        
        BLEModel *model=[BLEModel new];
        model.nameStr=peripheral.name;
        model.rssStr=[NSString stringWithFormat:@"%@",RSSI];
        model.addressStr=str;
        model.peripheral=peripheral;
        [self.managerDelegate receiveDataWithBLEmodel:model result:@"0"];
    }
    
    
}
//连接外设成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    self.connectDevice = YES;
    NSLog(@"-- 成功连接外设 --：%@",peripheral.name);
    NSLog(@"Did connect to peripheral: %@",peripheral);
    peripheral.delegate = self;
    [peripheral discoverServices:nil];
    [self.centralManager stopScan];
    [self stopBleScan];
    
    [self.managerDelegate connectPeripheralSuccess:peripheral.name];
}

//断开外设连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    self.connectDevice = NO;
    // LogRed(@"蓝牙已断开");
    [self.managerDelegate disConnectPeripheral];

}

//连接外设失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    // LogRed(@"-- 连接失败 --");
     self.connectDevice = NO;

}

#pragma mark - CBPeripheralDelegate
//发现服务时调用的方法
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"%s", __func__);
    NSLog(@"error：%@", error);
    for (CBService *service in peripheral.services) {
        [peripheral  discoverCharacteristics:nil forService:service];
        
    }
}

//发现服务的特征值后回调的方法
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    for (CBCharacteristic *c in service.characteristics) {
        [peripheral discoverDescriptorsForCharacteristic:c];
    }
    
    if ([service.UUID.UUIDString isEqualToString:serviceUUID]) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            
            if ([characteristic.UUID.UUIDString isEqualToString:writeUUID]) {
                
                if (characteristic) {
                    self.myCharacteristic  = characteristic;
                }
            }
            if ([characteristic.UUID.UUIDString isEqualToString:receiveUUID]) {
                
                if (characteristic) {
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
            }
            
        }
    }

}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    // NSLog(@"didUpdateNotificationStateForCharacteristic: %@",characteristic.value);
}
//特征值更新时回调的方法
#pragma mark - 接收数据
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"characteristic.value==%@",characteristic.value);
     NSString *version = [UIDevice currentDevice].systemVersion;
     NSString *dataStr = @"";
     if (version.floatValue >= 13.0) {
          NSString *valueStr=[NSString stringWithFormat:@"%@",characteristic.value];
          if ([valueStr containsString:@"bytes = 0x"]) {
               NSRange range = [valueStr rangeOfString:@"bytes = 0x"];
               NSString *valueStrr=[valueStr substringFromIndex:range.location + range.length];
//               NSArray *aa=[valueStrr componentsSeparatedByString:@" "];
//               NSMutableString *bb=[[NSMutableString alloc]init];
//               for (NSString *str in aa) {
//                    [bb appendString:str];
//               }
               dataStr =[NSString stringWithFormat:@"%@",[valueStrr substringToIndex:valueStrr.length - 1]];
          }
          
     } else {
          NSString *valueStr=[NSString stringWithFormat:@"%@",characteristic.value];
          NSString *valueStrr=[valueStr substringWithRange:NSMakeRange(1, valueStr.length-2)];
          NSArray *aa=[valueStrr componentsSeparatedByString:@" "];
          NSMutableString *bb=[[NSMutableString alloc]init];
          for (NSString *str in aa) {
               [bb appendString:str];
          }
          dataStr =[NSString stringWithFormat:@"%@",bb];
     }
    
     NSString *typeStr;
     if (dataStr.length>10) {
          typeStr=[dataStr substringWithRange:NSMakeRange(8, 2)];
     }
     else
     {
          typeStr=@"10000";
     }
     
     if (self.singleLableStr.length>0) {
          //单次盘点n标签
          [self.singleLableStr appendString:dataStr];
          if (dataStr.length<40) {
               NSLog(@"self.singleLableStr===%@",self.singleLableStr);
               //  天线号 1 个字节,信号值 2 个字节,1个字节校验码,2个字节 RSSI
               
               //NSInteger countStr1 = [AppHelper getDecimalByBinary:[AppHelper getBinaryByHex:[self.singleLableStr substringWithRange:NSMakeRange(10, 2)]]];
               NSString *secondStr = [self.singleLableStr substringWithRange:NSMakeRange(10, 2)];
               NSString *binarySecondStr = [AppHelper getBinaryByHex:secondStr];
               NSString *headFive = [binarySecondStr substringToIndex:5];
               NSInteger realEPCDataLong = [AppHelper getDecimalByBinary:headFive];
               NSInteger count = (self.singleLableStr.length - 14) - (realEPCDataLong * 2 + 2 + 1 + 2 + 1) * 2  - 12 * 2;
               if (count > 0) {
                    //epc+tid+User
                    self.tagTypeStr = @"2";
                    NSString *realEPCStr = [self.singleLableStr substringWithRange:NSMakeRange(14, realEPCDataLong * 2 * 2)];
                    NSString *TidStr = [self.singleLableStr substringWithRange:NSMakeRange(14 + realEPCDataLong * 2 * 2, 12 * 2)];
                    NSString *userAndRSSIStr = [self.singleLableStr substringWithRange:NSMakeRange(14 + realEPCDataLong * 2 * 2 + 12 * 2, self.singleLableStr.length - (14 + realEPCDataLong * 2 * 2 + 12 * 2) - 4 * 2)];
                    [self.dataSource addObject:realEPCStr];
                    [self.countArr addObject:@"1"];
                    [self.dataSource1 addObject:TidStr];
                    [self.countArr1 addObject:@"1"];
                    [self.dataSource2 addObject:userAndRSSIStr];
                    [self.countArr2 addObject:@"1"];
               }
               else if (count == 0)
               {
                    //epc+tid
                    self.tagTypeStr = @"1";
                    NSString *realEPCStr = [self.singleLableStr substringWithRange:NSMakeRange(14, realEPCDataLong * 2 * 2)];
                    NSString *TidAndRSSIStr = [self.singleLableStr substringWithRange:NSMakeRange(14 + realEPCDataLong * 2 * 2, (12 + 2) * 2)];
                    [self.dataSource addObject:realEPCStr];
                    [self.countArr addObject:@"1"];
                    [self.dataSource1 addObject:TidAndRSSIStr];
                    [self.countArr1 addObject:@"1"];
               }
               else
               {
                    //epc
                    self.tagTypeStr = @"0";
                    NSString *realEPCStr = [self.singleLableStr substringWithRange:NSMakeRange(14, realEPCDataLong * 2 * 2)];
                    NSString *RSSIStr = [self.singleLableStr substringWithRange:NSMakeRange(14 + realEPCDataLong * 2 * 2, 4)];
                    realEPCStr = [realEPCStr stringByAppendingString:RSSIStr];
                    [self.dataSource addObject:realEPCStr];
                    [self.countArr addObject:@"1"];
               }
               
               
               
               [self.managerDelegate receiveDataWithBLEDataSource:self.dataSource allCount:self.allCount countArr:self.countArr dataSource1:self.dataSource1 countArr1:self.countArr1 dataSource2:self.dataSource2 countArr2:self.countArr2];
              
               
               self.singleLableStr=[[NSMutableString alloc]init];
               self.isSingleSaveLable = NO;
          }
     }
     
     if (self.getMiStr.length>0) {
          //获取密钥
          [self.getMiStr appendString:dataStr];
          if (dataStr.length<40) {
               NSLog(@"self.getMiStr===%@",self.getMiStr);
               NSString *aa=[NSString stringWithFormat:@"%@",self.getMiStr];
               NSString *strrr=[aa substringWithRange:NSMakeRange(14, 64)];
               [self.managerDelegate receiveMessageWithtype:@"e32" dataStr:strrr];
               self.getMiStr=[[NSMutableString alloc]init];
          }
     }
     
     if (self.encryStr.length>0) {
          //SM4加密
          
          [self.encryStr appendString:dataStr];
          if (dataStr.length<40) {
                NSString *aa=[NSString stringWithFormat:@"%@",self.encryStr];
               NSLog(@"aa===%@",aa);
               
               NSString *strrr=[aa substringWithRange:NSMakeRange(12, aa.length-12-6)];
               NSLog(@"strrr===%@",strrr);
               [self.managerDelegate receiveMessageWithtype:@"e33" dataStr:strrr];
               self.encryStr=[[NSMutableString alloc]init];
          }
     }
     
     if (self.dencryStr.length>0) {
          //SM4解密
          [self.dencryStr appendString:dataStr];
          if (dataStr.length<40) {
               NSString *aa=[NSString stringWithFormat:@"%@",self.dencryStr];
               NSString *strrr=[aa substringWithRange:NSMakeRange(12, aa.length-12-6)];
               [self.managerDelegate receiveMessageWithtype:@"e34" dataStr:strrr];
               self.dencryStr=[[NSMutableString alloc]init];
          }
     }
     
     if (self.USERStr.length>0) {
          //USER解密
          [self.USERStr appendString:dataStr];
          if (dataStr.length<40) {
               NSString *aa=[NSString stringWithFormat:@"%@",self.USERStr];
               NSString *strrr=[aa substringWithRange:NSMakeRange(12, aa.length-12-6)];
               [self.managerDelegate receiveMessageWithtype:@"e36" dataStr:strrr];
               self.USERStr=[[NSMutableString alloc]init];
          }
     }
     
     if (self.readStr.length>0) {
          //读标签
          [self.readStr appendString:dataStr];
          if (dataStr.length<40) {
               NSString *aa=[NSString stringWithFormat:@"%@",self.readStr];
               NSString *valueStr=[aa substringWithRange:NSMakeRange(18, aa.length-18-6)];
               [self.managerDelegate receiveMessageWithtype:@"85" dataStr:valueStr];
               self.readStr=[[NSMutableString alloc]init];
          }
     }
     
     if (self.rcodeStr.length>0) {
          //二维码
          [self.rcodeStr appendString:dataStr];
          if (dataStr.length<40) {
               NSLog(@"66666");
               NSString *aa=[NSString stringWithFormat:@"%@",self.rcodeStr];
               NSString *valueStr=[aa substringWithRange:NSMakeRange(12, aa.length-12-6)];
               NSMutableString *strrr=[[NSMutableString alloc]init];
               for(int i =1; i < [valueStr length]+1; i=i+2)
               {
                    NSString *aa=[valueStr substringWithRange:NSMakeRange(i, 1)];
                    [strrr appendString:aa];
               }
               NSString *strrrr=[NSString stringWithFormat:@"%@",strrr];
               [self.managerDelegate receiveMessageWithtype:@"e55" dataStr:strrrr];
               self.rcodeStr=[[NSMutableString alloc]init];
               self.isCodeLab = NO;
          }
     }
     
     
     if (self.isgetLab==NO) {
          //不是获取标签的
          
          
          if ([typeStr isEqualToString:@"01"]) {
               //获取硬件版本号
               if (self.isGetVerson) {
                    NSString *strr=[dataStr substringWithRange:NSMakeRange(10, 6)];
                    [self.managerDelegate receiveMessageWithtype:@"01" dataStr:strr];
                    self.isGetVerson = NO;
               }
        
          }
          
          else if ([typeStr isEqualToString:@"03"])
          {
               if (self.isGetVerson) {
                    //获取固件版本号
                    NSString *str1=[dataStr substringWithRange:NSMakeRange(10, 2)];
                    NSString *str2=[dataStr substringWithRange:NSMakeRange(12, 2)];
                    NSString *str3=[dataStr substringWithRange:NSMakeRange(14, 2)];
                    NSString *strr=[NSString stringWithFormat:@"V%ld.%ld%ld",str1.integerValue,str2.integerValue,str3.integerValue];
                    [self.managerDelegate receiveMessageWithtype:@"03" dataStr:strr];
                    self.isGetVerson = NO;
               }
               
          }
          else if ([typeStr isEqualToString:@"c9"])
          {
               //获取升级固件版本号
               NSString *strr=[dataStr substringWithRange:NSMakeRange(10, 6)];
               [self.managerDelegate receiveMessageWithtype:@"c9" dataStr:strr];
          }
          else if ([typeStr isEqualToString:@"05"])
          {
               //获取设备ID
               NSString *strr=[dataStr substringWithRange:NSMakeRange(10, 8)];
               NSLog(@"strr==%@",strr);
          }
          else if ([typeStr isEqualToString:@"69"])
          {
               //软件复位
               NSString *strr=[dataStr substringWithRange:NSMakeRange(10, 2)];
               if ([strr isEqualToString:@"01"]) {
                   [self.managerDelegate receiveMessageWithtype:@"69" dataStr:@"软件复位成功"];
               }
               else
               {
                    [self.managerDelegate receiveMessageWithtype:@"69" dataStr:@"软件复位失败"];
               }
          } else if ([typeStr isEqualToString:@"11"])
          {
               if (self.isSetEmissionPower) {
                    //设置发射功率
                    NSString *strr=[dataStr substringWithRange:NSMakeRange(10, 2)];
                    if ([strr isEqualToString:@"01"]) {
                         [self.managerDelegate receiveMessageWithtype:@"11" dataStr:@"Set power successfully"];
                    }
                    else
                    {
                         [self.managerDelegate receiveMessageWithtype:@"11" dataStr:@"Power setting fails"];
                    }
                    self.isSetEmissionPower = NO;
               }
               
          }
          else if ([typeStr isEqualToString:@"13"])
          {
               if (self.isGetEmissionPower) {
                    //获取当前发射功率
                    NSInteger a=[BluetoothUtil getzhengshuWith:[dataStr substringWithRange:NSMakeRange(14, 1)]];
                    NSInteger b=[BluetoothUtil getzhengshuWith:[dataStr substringWithRange:NSMakeRange(15, 1)]];
                    NSInteger c=[BluetoothUtil getzhengshuWith:[dataStr substringWithRange:NSMakeRange(16, 1)]];
                    NSInteger d=[BluetoothUtil getzhengshuWith:[dataStr substringWithRange:NSMakeRange(17, 1)]];
                    NSInteger count=(a*16*16*16+b*16*16+c*16+d)/100;
                    [self.managerDelegate receiveMessageWithtype:@"13" dataStr:[NSString stringWithFormat:@"%ld",count]];
                    self.isGetEmissionPower = YES;
               }
               
               
          }
          else if ([typeStr isEqualToString:@"15"])
          {
               //跳频设置
               NSString *strr=[dataStr substringWithRange:NSMakeRange(10, 2)];
               if ([strr isEqualToString:@"01"]) {
                    NSLog(@"跳频设置成功");
                    [self.managerDelegate receiveMessageWithtype:@"15" dataStr:@"Set the frequency point successfully"];
               }
               else
               {
                    NSLog(@"跳频设置失败");
                     [self.managerDelegate receiveMessageWithtype:@"15" dataStr:@"Failed to set frequency point"];
               }
          }
          else if ([typeStr isEqualToString:@"2d"])
          {
               if (self.isRegion) {
                    // 区域设置
                    NSString *strr=[dataStr substringWithRange:NSMakeRange(10, 2)];
                    if ([strr isEqualToString:@"01"]) {
                         NSLog(@"区域设置成功");
                         
                         [self.managerDelegate receiveMessageWithtype:@"2d" dataStr:@"Set frequency successfully"];
                    }
                    else
                    {
                         [self.managerDelegate receiveMessageWithtype:@"2d" dataStr:@"Failed to set frequency"];
                    }
                    self.isRegion = NO;
               }
              
          }
          else if ([typeStr isEqualToString:@"2f"])
          {
               //获取区域设置
               NSString *strr=[dataStr substringWithRange:NSMakeRange(10, 2)];
               if ([strr isEqualToString:@"01"]) {
                    NSLog(@"区域设置成功");
                    NSString *valueStr=[dataStr substringWithRange:NSMakeRange(12, 2)];
                    NSString *messageStr;
                    if ([valueStr isEqualToString:@"01"]) {
                         messageStr=@"0";
                    }
                    else if ([valueStr isEqualToString:@"02"])
                    {
                          messageStr=@"1";
                    }
                    else if ([valueStr isEqualToString:@"04"])
                    {
                          messageStr=@"2";
                    }
                    else if ([valueStr isEqualToString:@"08"])
                    {
                          messageStr=@"3";
                    }
                    else if ([valueStr isEqualToString:@"16"])
                    {
                          messageStr=@"4";
                    }
                    else if ([valueStr isEqualToString:@"32"])
                    {
                          messageStr=@"5";
                    }
                    [self.managerDelegate receiveMessageWithtype:@"2f" dataStr:messageStr];
               }
               else
               {
                    [self.managerDelegate receiveMessageWithtype:@"2f" dataStr:@"读取频率失败"];
               }
               
          }
          else if ([typeStr isEqualToString:@"8d"])
          {
               //停止连续盘存标签
               NSString *strr=[dataStr substringWithRange:NSMakeRange(10, 2)];
               if ([strr isEqualToString:@"01"]) {
                    NSLog(@"停止连续盘存标签成功");
                    self.isgetLab=NO;
                    _tagStr=[[NSMutableString alloc]init];
               }
          }
          else if ([typeStr isEqualToString:@"85"])
          {
               //读标签
               if (dataStr.length<40) {
                    NSString *strr=[dataStr substringWithRange:NSMakeRange(18, dataStr.length-18-6)];
                    [self.managerDelegate receiveMessageWithtype:@"85" dataStr:strr];
               }
               else
               {
                    if (dataStr.length==40) {
                         NSString *aa=[dataStr substringWithRange:NSMakeRange(dataStr.length-4, 4)];
                         if ([aa isEqualToString:@"0d0a"]) {
                              NSString *strr=[dataStr substringWithRange:NSMakeRange(18, dataStr.length-18-6)];
                              [self.managerDelegate receiveMessageWithtype:@"85" dataStr:strr];
                         }
                         else
                         {
                              self.readStr=[[NSMutableString alloc]init];
                              [self.readStr appendString:dataStr];
                         }
                    }
                   
               }
               
          }
          else if ([typeStr isEqualToString:@"87"])
          {
               //写标签
               NSString *strr=[dataStr substringWithRange:NSMakeRange(10, 2)];
               if ([strr isEqualToString:@"01"]) {
                    [self.managerDelegate receiveMessageWithtype:@"87" dataStr:@"Successful tag writing"];
               }
               else
               {
                    [self.managerDelegate receiveMessageWithtype:@"87" dataStr:@"Failed to write tag"];
               }
          }
          else if ([typeStr isEqualToString:@"89"])
          {
               //lock标签
               NSString *strr=[dataStr substringWithRange:NSMakeRange(10, 2)];
               if ([strr isEqualToString:@"01"]) {
                    [self.managerDelegate receiveMessageWithtype:@"89" dataStr:@"Lock label successful"];
               }
               else
               {
                    [self.managerDelegate receiveMessageWithtype:@"89" dataStr:@"Lock label failed"];
               }
          }
          else if ([typeStr isEqualToString:@"8b"])
          {
               //销毁
               NSString *strr=[dataStr substringWithRange:NSMakeRange(10, 2)];
               if ([strr isEqualToString:@"01"]) {
                    [self.managerDelegate receiveMessageWithtype:@"8b" dataStr:@"Destruction of success"];
               }
               else
               {
                    [self.managerDelegate receiveMessageWithtype:@"8b" dataStr:@"Destruction of failure"];
               }
          } else if ([typeStr isEqualToString:@"81"]) {
               if (self.isSingleSaveLable) {
                    //单次盘存标签
                    self.singleLableStr=[[NSMutableString alloc]init];
                    [self.singleLableStr appendString:dataStr];
               }
          } else if ([typeStr isEqualToString:@"71"]) {
               if (self.isSetTag) {
                    //设置标签读取格式
                    self.isSetTag = NO;
                    NSString *strr=[dataStr substringWithRange:NSMakeRange(10, 2)];
                    if ([strr isEqualToString:@"01"]) {
                         [self.managerDelegate receiveMessageWithtype:@"71" dataStr:@"Successful setup"];
                    }
               }
          } else if ([typeStr isEqualToString:@"73"]) {
               if (self.isGetTag) {
                    //获取标签读取格式
                    self.isGetTag = NO;
                    NSString *strr=[dataStr substringWithRange:NSMakeRange(10, 2)];
                    if ([strr isEqualToString:@"01"]) {
                         NSString *epcstr=[dataStr substringWithRange:NSMakeRange(13, 1)];
                         NSString *addreStr=[BluetoothUtil becomeNumberWith:[dataStr substringWithRange:NSMakeRange(14, 2)]];
                         NSString *addreLenStr=[BluetoothUtil becomeNumberWith:[dataStr substringWithRange:NSMakeRange(16, 2)]];
                         NSString *allStr=[NSString stringWithFormat:@"%@ %@ %@",epcstr,addreStr,addreLenStr];
                         [self.managerDelegate receiveMessageWithtype:@"73" dataStr:allStr];
                    }
               }
          } else if ([typeStr isEqualToString:@"e3"]) {
               if ([self.typeStr isEqualToString:@"1"]) {
                    //设置密钥
                    NSString *strr=[dataStr substringWithRange:NSMakeRange(10, 2)];
                    if ([strr isEqualToString:@"01"]) {
                        NSLog(@"设置密钥成功");
                         [self.managerDelegate receiveMessageWithtype:@"e31" dataStr:@"设置密钥成功"];
                    }
                    else
                    {
                         [self.managerDelegate receiveMessageWithtype:@"e31" dataStr:@"设置密钥失败"];
                    }
               } else if ([self.typeStr isEqualToString:@"2"]) {
                    //获取密钥
                    self.getMiStr=[[NSMutableString alloc]init];
                    [self.getMiStr appendString:dataStr];

               } else if ([self.typeStr isEqualToString:@"3"]) {
                    //SM4加密
                    self.encryStr=[[NSMutableString alloc]init];
                    [self.encryStr appendString:dataStr];
                    
               }
               else if ([self.typeStr isEqualToString:@"4"])
               {
                    //SM4解密
                    self.dencryStr=[[NSMutableString alloc]init];
                    [self.dencryStr appendString:dataStr];
               }
               else if ([self.typeStr isEqualToString:@"5"])
               {
                    //USER加密
                     NSString *strrr=[dataStr substringWithRange:NSMakeRange(10, 2)];
                    if ([strrr isEqualToString:@"01"]) {
                         NSLog(@"USER加密成功");
                        [self.managerDelegate receiveMessageWithtype:@"e35" dataStr:@"写成功"];
                    }
                    else
                    {
                        [self.managerDelegate receiveMessageWithtype:@"e35" dataStr:@"写失败"];
                    }
               }
               else if ([self.typeStr isEqualToString:@"6"])
               {
                    //USER解密
                    self.USERStr=[[NSMutableString alloc]init];
                    [self.USERStr appendString:dataStr];
                   
               }
             
          }
          else if ([typeStr isEqualToString:@"e5"])
          {
               NSLog(@"dataStr===========%@",dataStr);
               NSLog(@"dataStr.length====%ld",dataStr.length);
               
               NSLog(@"self.isCodeLab=====%d",self.isCodeLab);
               
               
               //开启蜂鸣器
               if (self.isOpenBuzzer) {
                    NSString *strr=[dataStr substringWithRange:NSMakeRange(10, 2)];
                    if ([strr isEqualToString:@"01"]) {
                         [self.managerDelegate receiveMessageWithtype:@"e50" dataStr:@"Buzzer turned on successfully"];
                    }
                    else
                    {
                         
                    }
                    self.isOpenBuzzer = NO;
               }
               
               if (self.isCloseBuzzer) {
                    NSString *strr=[dataStr substringWithRange:NSMakeRange(10, 2)];
                    if ([strr isEqualToString:@"01"]) {
                         [self.managerDelegate receiveMessageWithtype:@"e51" dataStr:@"Buzzer closed successfully"];
                    }
                    else
                    {
                         // [self.managerDelegate receiveMessageWithtype:@"e5" dataStr:@"Buzzer closed successfully"];
                    }
                    self.isCloseBuzzer = NO;
               }
               
               
               if (self.isGetBattery) {
                    //获取电池电量
                    NSString *battyStr=[dataStr substringWithRange:NSMakeRange(12, 2)];
                    NSInteger n = strtoul([battyStr UTF8String], 0, 16);//16进制数据转10进制的NSInteger
                    NSLog(@"battyStr===%@",battyStr);
                    NSString *batStr=[NSString stringWithFormat:@"%ld",n];
                    [self.managerDelegate receiveMessageWithtype:@"e5" dataStr:batStr];
                    self.isGetBattery = NO;
                    return;
               }
                    
                    NSLog(@"1111111111111");
                    
               if (self.isCodeLab) {
                    //扫描二维码
                    if (dataStr.length<40) {
                         NSString *strr=[dataStr substringWithRange:NSMakeRange(12, dataStr.length-12-6)];
                         NSLog(@"strr===%@",strr);
                         NSMutableString *strrr=[[NSMutableString alloc]init];
                         for(int i =1; i < [strr length]+1; i=i+2)
                         {
                              NSString *aa=[strr substringWithRange:NSMakeRange(i, 1)];
                              [strrr appendString:aa];
                         }
                         NSString *strrrr=[NSString stringWithFormat:@"%@",strrr];
                         NSLog(@"strrr==========%@",strrr);
                         NSLog(@"strrrr==========%@",strrrr);
                         [self.managerDelegate receiveMessageWithtype:@"e55" dataStr:strrrr];
                         self.isCodeLab=NO;
                    }
                    else
                    {
                         if (dataStr.length==40) {
                              
                              NSLog(@"hahahahah");
                              
                              NSString *aa=[dataStr substringWithRange:NSMakeRange(dataStr.length-4, 4)];
                              if ([aa isEqualToString:@"0d0a"]) {
                                   
                                   NSString *strr=[dataStr substringWithRange:NSMakeRange(12, dataStr.length-12-6)];
                                   NSMutableString *strrr=[[NSMutableString alloc]init];
                                   for(int i =1; i < [strr length]+1; i=i+2)
                                   {
                                        NSString *aa=[strr substringWithRange:NSMakeRange(i, 1)];
                                        [strrr appendString:aa];
                                   }
                                   NSString *strrrr=[NSString stringWithFormat:@"%@",strrr];
                                   [self.managerDelegate receiveMessageWithtype:@"e55" dataStr:strrrr];
                                   self.isCodeLab=NO;
                              }
                              else
                              {
                                   self.rcodeStr=[[NSMutableString alloc]init];
                                   [self.rcodeStr appendString:dataStr];
                              }
                         }
                         
                    }
               }
          }
          else if ([typeStr isEqualToString:@"35"])
          {//获取设备温度
               if (self.isTemperature) {
                    NSString *battyStr=[dataStr substringWithRange:NSMakeRange(12, 4)];
                    NSInteger n = strtoul([battyStr UTF8String], 0, 16);//16进制数据转10进制的NSInteger
                    NSString *temStr = [NSString stringWithFormat:@"%ld",n/100];
                    [self.managerDelegate receiveMessageWithtype:@"35" dataStr:temStr];
                    self.isTemperature = NO;
               }
               
          }
          else if ([typeStr isEqualToString:@"c1"])
          {//进入升级模式
               NSString *Strr=[dataStr substringWithRange:NSMakeRange(10, 2)];
               [self.managerDelegate receiveMessageWithtype:@"c1" dataStr:Strr];
          }
          else if ([typeStr isEqualToString:@"c3"])
          {//进入升级接收数据
               NSString *Strr=[dataStr substringWithRange:NSMakeRange(10, 2)];
               [self.managerDelegate receiveMessageWithtype:@"c3" dataStr:Strr];
          }
          else if ([typeStr isEqualToString:@"c5"])
          {//进入升级发送数据
               NSString *Strr=[dataStr substringWithRange:NSMakeRange(10, 2)];
               [self.managerDelegate receiveMessageWithtype:@"c5" dataStr:Strr];
          }
          else if ([typeStr isEqualToString:@"c7"])
          {//退出升级模式
               NSString *Strr=[dataStr substringWithRange:NSMakeRange(10, 2)];
               [self.managerDelegate receiveMessageWithtype:@"c7" dataStr:Strr];
          }
          else if ([typeStr isEqualToString:@"e6"])
          {//按硬件scan按钮
               
               [self.managerDelegate receiveMessageWithtype:@"e6" dataStr:@""];
          }
     }
     else
     {
          
          //获取标签
       if ([typeStr isEqualToString:@"e6"])
           {//按硬件scan按钮

               [self.managerDelegate receiveMessageWithtype:@"e6" dataStr:@""];
               NSLog(@"666666666666666");

                return;
           }
          
          //拿到标签列表
          if (dataStr.length==40) {
               [_tagStr appendString:dataStr];
          }
          else
          {
               [_tagStr appendString:dataStr];
               if ([_tagStr containsString:@"bytes=0x"]) {
                    NSRange range = [_tagStr rangeOfString:@"bytes=0x"];
                    _tagStr = [_tagStr substringFromIndex:range.length + range.location];
               }
               NSLog(@"_tagStr=====%@",_tagStr);
               NSString *tagStr=[NSString stringWithFormat:@"%@",_tagStr];
               NSMutableArray *arr=[[NSMutableArray alloc]init];   //getNewLabTagWith
               if (self.isNewLab) {
                    
                    //先判断是epc或者是epc+tid或者是epc+tid+User
                    
                    //  标签长度 - (EPC长度 + 2) * 2 - 12 * 2 > 2 * 2 个字节 为 EPC + TID + USER
                    //  标签长度 - (EPC长度 + 2) * 2 - 12 * 2 = 2 * 2 个字节 为 EPC + TID
                    //  标签长度 - (EPC长度 + 2) * 2 - 12 * 2 < 2 * 2 个字节 为 EPC
                    
                    if (tagStr.length < 20) {
                         return;
                    }
                    NSInteger countStr1 = [AppHelper getDecimalByBinary:[AppHelper getBinaryByHex:[tagStr substringWithRange:NSMakeRange(16, 2)]]];
                    NSString *secondStr = [tagStr substringWithRange:NSMakeRange(18, 2)];
                    NSString *binarySecondStr = [AppHelper getBinaryByHex:secondStr];
                    NSString *headFive = [binarySecondStr substringToIndex:5];
                    NSInteger realEPCDataLong = [AppHelper getDecimalByBinary:headFive];
                    NSInteger count = countStr1 - (realEPCDataLong * 2 + 2)  - 12;
                    if (count > 2) {
                         //epc+tid+User
                         self.tagTypeStr = @"2";
                    }
                    else if (count == 2)
                    {
                         //epc+tid
                         self.tagTypeStr = @"1";
                    }
                    else
                    {
                         //epc
                         self.tagTypeStr = @"0";
                    }
                    
                    arr=[BluetoothUtil getNewLabTagWith:tagStr dataSource:self.dataSource countArr:self.countArr dataSource1:self.dataSource1 countArr1:self.countArr1 dataSource2:self.dataSource2 countArr2:self.countArr2];
               }
               else
               {
                    arr=[BluetoothUtil getLabTagWith:tagStr dataSource:self.dataSource countArr:self.countArr];
               }
               
               
               if (arr.count==6) {
                    
                    
                    self.countArr=[NSMutableArray arrayWithArray:arr[0]];
                    self.dataSource=[NSMutableArray arrayWithArray:arr[1]];
                    self.countArr1=[NSMutableArray arrayWithArray:arr[2]];
                    self.dataSource1=[NSMutableArray arrayWithArray:arr[3]];
                    self.countArr2=[NSMutableArray arrayWithArray:arr[4]];
                    self.dataSource2=[NSMutableArray arrayWithArray:arr[5]];
                    
                    [self.managerDelegate receiveDataWithBLEDataSource:self.dataSource allCount:self.allCount countArr:self.countArr dataSource1:self.dataSource1 countArr1:self.countArr1 dataSource2:self.dataSource2 countArr2:self.countArr2];
               } else if (arr.count == 4) {
                    self.countArr=[NSMutableArray arrayWithArray:arr[0]];
                    self.dataSource=[NSMutableArray arrayWithArray:arr[1]];
                    self.countArr1=[NSMutableArray arrayWithArray:arr[2]];
                    self.dataSource1=[NSMutableArray arrayWithArray:arr[3]];
                    
                    [self.managerDelegate receiveDataWithBLEDataSource:self.dataSource allCount:self.allCount countArr:self.countArr dataSource1:self.dataSource1 countArr1:self.countArr1 dataSource2:self.dataSource2 countArr2:self.countArr2];
               } else if (arr.count == 2) {
                    self.countArr=[NSMutableArray arrayWithArray:arr[0]];
                    self.dataSource=[NSMutableArray arrayWithArray:arr[1]];
                    [self.managerDelegate receiveDataWithBLEDataSource:self.dataSource allCount:self.allCount countArr:self.countArr dataSource1:self.dataSource1 countArr1:self.countArr1 dataSource2:self.dataSource2 countArr2:self.countArr2];
               }
               _tagStr=[[NSMutableString alloc]init];
               [self getLabMessage];
               
          }
     }
     
}
#pragma mark 写数据后回调
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic  error:(NSError *)error {
    
    if (error) {
        
        NSLog(@"Error writing characteristic value: %@",
              
              [error localizedDescription]);
        
        return;
        
    }
    
    NSLog(@"写入%@成功",characteristic);
    
}
-(void)notifyCharacteristic:(CBPeripheral *)peripheral
             characteristic:(CBCharacteristic *)characteristic{
    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
    
}
-(void)cancelNotifyCharacteristic:(CBPeripheral *)peripheral
                   characteristic:(CBCharacteristic *)characteristic{
    
    [peripheral setNotifyValue:NO forCharacteristic:characteristic];
}


- (NSString *)getVisiableIDUUID:(NSString *)peripheralIDUUID
{
    if (!peripheralIDUUID.length) {
        return @"";
    }
    peripheralIDUUID = [peripheralIDUUID stringByReplacingOccurrencesOfString:@"-" withString:@""];
    peripheralIDUUID = [peripheralIDUUID stringByReplacingOccurrencesOfString:@"<" withString:@""];
    peripheralIDUUID = [peripheralIDUUID stringByReplacingOccurrencesOfString:@">" withString:@""];
    peripheralIDUUID = [peripheralIDUUID stringByReplacingOccurrencesOfString:@" " withString:@""];
    peripheralIDUUID = [peripheralIDUUID substringFromIndex:peripheralIDUUID.length - 12];
    peripheralIDUUID = [peripheralIDUUID uppercaseString];
    NSData *bytes = [peripheralIDUUID dataUsingEncoding:NSUTF8StringEncoding];
    Byte * myByte = (Byte *)[bytes bytes];
    
    
    NSMutableString *result = [[NSMutableString alloc] initWithString:@""];
    for (int i = 5; i >= 0; i--) {
        [result appendString:[NSString stringWithFormat:@"%@",[[NSString alloc] initWithBytes:&myByte[i*2] length:2 encoding:NSUTF8StringEncoding] ]];
    }
    
    for (int i = 1; i < 6; i++) {
        [result insertString:@":" atIndex:3*i-1 ];
    }
    
    return result;
}


#pragma mark - Setter and Getter

- (CBCentralManager *)centralManager
{
    if (!_centralManager ) {
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    return _centralManager;
}

- (NSMutableArray *)peripheralArray
{
    if (!_peripheralArray) {
        _peripheralArray = [[NSMutableArray alloc] init];
    }
    return _peripheralArray;
}

- (CBCharacteristic *)myCharacteristic
{
    return _myCharacteristic;
}

- (NSString *)centralManagerStateDescribe:(CBCentralManagerState )state
{
    NSString *descStr = @"";
    switch (state) {
        case CBCentralManagerStateUnknown:
            
            break;
        case CBCentralManagerStatePoweredOff:
            descStr = @"请打开蓝牙";
            break;
        default:
            break;
    }
    return descStr;
}

- (void)dealloc
{
    [_connectTime invalidate];
    _connectTime = nil;
}

@end
