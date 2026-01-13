//
//  RFIDBlutoothManager.h
//  RFID_ios
//
//  Created by chainway on 2018/4/26.
//  Copyright © 2018年 chainway. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BLEModel.h"
#import "BluetoothUtil.h"


@protocol FatScaleBluetoothManager <NSObject>

@optional
//蓝牙链接失败
- (void)connectBluetoothFailWithMessage:(NSString *)msg;
//蓝牙连接超时
- (void)connectBluetoothTimeout;
//链接到数据
- (void)receiveDataWith:(id)parseModel dataSource:(NSMutableArray *)dataSource;
//列表数据
- (void)receiveDataWithBLEmodel:(BLEModel *)model result:(NSString *)result;
//首页标签数据
- (void)receiveDataWithBLEDataSource:(NSMutableArray *)dataSource allCount:(NSInteger)allCount countArr:(NSMutableArray *)countArr dataSource1:(NSMutableArray *)dataSource1 countArr1:(NSMutableArray *)countArr1 dataSource2:(NSMutableArray *)dataSource2 countArr2:(NSMutableArray *)countArr2;
//首页标签数据
- (void)receiveRcodeDataWithBLEDataSource:(NSMutableArray *)dataSource;
//
- (void)receiveMessageWithtype:(NSString *)typeStr dataStr:(NSString *)dataStr;
//连接外设成功
- (void)connectPeripheralSuccess:(NSString *)nameStr;
//断开外设
-(void)disConnectPeripheral;
//更改蓝牙设备名称成功
- (void)updateBLENameSuccess;



@end
@protocol PeripheralAddDelegate <NSObject>

@optional

- (void)addPeripheralWithPeripheral:(BLEModel *)peripheralModel;

@end


@interface RFIDBlutoothManager : NSObject


@property (nonatomic, assign) BOOL connectDevice;

+ (instancetype)shareManager;


@property (nonatomic,strong)NSMutableArray *dataSource;

@property (nonatomic,strong)NSMutableArray *countArr;

@property (nonatomic,strong)NSMutableArray *dataSource1;

@property (nonatomic,strong)NSMutableArray *countArr1;

@property (nonatomic,strong)NSMutableArray *dataSource2;

@property (nonatomic,strong)NSMutableArray *countArr2;





@property (nonatomic, assign) NSInteger allCount;

@property (nonatomic, assign) int num;

@property (nonatomic,assign)BOOL isgetLab;//是否是获取标签

@property (nonatomic,assign)BOOL isNewLab;//是否是获取升级后的标签

@property (nonatomic,assign)BOOL isGetVerson;//是否是获取版本号

@property (nonatomic,assign)BOOL isGetBattery;//是否是获取电量

@property (nonatomic,assign)BOOL isCodeLab; //扫描二维码

@property (nonatomic,assign)BOOL isTemperature; //获取温度

@property (nonatomic,assign)BOOL isSetEmissionPower; //发射功率

@property (nonatomic,assign)BOOL isGetEmissionPower; //获取发射功率

@property (nonatomic,assign)BOOL isOpenBuzzer; //开启蜂鸣器

@property (nonatomic,assign)BOOL isCloseBuzzer; //关闭蜂鸣器

@property (nonatomic,assign)BOOL isSingleSaveLable; //单次盘点标签

@property (nonatomic,assign)BOOL isSetTag; //设置读取标签格式
@property (nonatomic,assign)BOOL isGetTag; //获取读取标签格式

@property (nonatomic,assign)BOOL isRegion;

@property (nonatomic,strong)NSMutableString *tagStr;

@property (nonatomic,copy)NSString *tagTypeStr;//判断连续获取新标签的时候返回的类型是epc还是epc+tid还是epc+tid+user

@property (nonatomic,copy)NSString *typeStr;

@property (nonatomic,strong)NSMutableString *getMiStr;//获取的SM4密码

@property (nonatomic,strong)NSMutableString *encryStr;//SM4加密

@property (nonatomic,strong)NSMutableString *dencryStr;//SM4解密

@property (nonatomic,strong)NSMutableString *USERStr;//USER解密

@property (nonatomic,strong)NSMutableString *readStr;//读数据

@property (nonatomic,strong)NSMutableString *rcodeStr;//二维码数据

@property (nonatomic,strong)NSMutableString *singleLableStr;//单次标签数据

@property (nonatomic,strong)NSMutableString *rcodeDataSource;//二维码数据数组






- (void)startBleScan;                // 开启蓝牙扫描
- (void)cancelConnectBLE;             //断开连接
- (void)closeBleAndDisconnect;       // 停止蓝牙扫描&断开


-(void)getFirmwareVersion2;//获取固件版本号
-(void)getBatteryLevel;//获取电池电量
-(void)getServiceTemperature;//获取设备当前温度
-(void)start2DScan;//开启2D扫描
-(void)getHardwareVersion;//获取硬件版本号
-(void)getFirmwareVersion;//获取固件版本号
-(void)getServiceID;//获取设备ID
-(void)softwareReset;//软件复位
-(void)setOpenBuzzer;//开启蜂鸣器
-(void)setCloseBuzzer;//关闭蜂鸣器


-(void)setEpcTidUserWithAddressStr:(NSString *)addressStr length:(NSString *)lengthStr epcStr:(NSString *)epcStr;//设置标签读取格式
-(void)getEpcTidUser;//获取标签读取格式

-(void)setLaunchPowerWithstatus:(NSString *)status antenna:(NSString *)antenna readStr:(NSString *)readStr writeStr:(NSString *)writeStr;//设置发射功率
-(void)getLaunchPower;//获取当前发射功率
-(void)detailChancelSettingWithstring:(NSString *)str;//跳频设置
-(void)getdetailChancelStatus;//获取当前跳频设置状态


-(void)setRegionWithsaveStr:(NSString *)saveStr regionStr:(NSString *)regionStr;//区域设置
-(void)getRegion;//获取区域设置

-(void)singleSaveLabel;//单次盘存标签

-(void)continuitySaveLabelWithCount:(NSString *)count;//连续盘存标签
-(void)StopcontinuitySaveLabel;//停止连续盘存标签

//password:4个字节的访问密码.  MMBstr:掩码的数据区(0x00为Reserve 0x01为EPC，0x02表示TID，0x03表示USR). MSAstr:为掩码的地址。 MDLstr:为掩码的长度。 Mdata:为掩码数据。 MBstr:为要写的数据区(0x00为Reserve 0x01为EPC，0x02表示TID，0x03表示USR)  SAstr :为要写数据区的地址。 DLstr :为要写的数据长度(字为单位)。 isfilter表示是否过滤
-(void)readLabelMessageWithPassword:(NSString *)password MMBstr:(NSString *)MMBstr MSAstr:(NSString *)MSAstr MDLstr:(NSString *)MDLstr MDdata:(NSString *)MDdata MBstr:(NSString *)MBstr SAstr:(NSString *)SAstr DLstr:(NSString *)DLstr isfilter:(BOOL)isfilter;//读标签数据区   成功

//password:4个字节的访问密码.  MMBstr:掩码的数据区(0x00为Reserve 0x01为EPC，0x02表示TID，0x03表示USR). MSAstr:为掩码的地址。 MDLstr:为掩码的长度。 Mdata:为掩码数据。 MBstr:为要写的数据区(0x00为Reserve 0x01为EPC，0x02表示TID，0x03表示USR)  SAstr :为要写数据区的地址。 DLstr :为要写的数据长度(字为单位)。 writeData :为写入的数据，高位在前。 isfilter表示是否过滤
-(void)writeLabelMessageWithPassword:(NSString *)password MMBstr:(NSString *)MMBstr MSAstr:(NSString *)MSAstr MDLstr:(NSString *)MDLstr MDdata:(NSString *)MDdata MBstr:(NSString *)MBstr SAstr:(NSString *)SAstr DLstr:(NSString *)DLstr writeData:(NSString *)writeData isfilter:(BOOL)isfilter;//写标签数据区   成功

//AP 为标签的 AccPwd 值;MMB 为启动过滤操作的 bank 号，0x01 表 示 EPC，0x02 表示 TID，0x03 表示 USR，其他值为非法值;MSA 为启动过滤 操作的起始地址，单位为 bit;MDL为启动过滤操作的过滤数据长度，单位为 bit，0x00 表示无过滤;MData 为启动过滤时的数据，单位为字节，若 MDL 不足整数 倍字节，不足位低位补 0;LD 共 3 个字节 24bit，其中，高 4bit 无效，第 0~9bit(共10bit)为 Action 位，第 10~19bit(共 10bit)为 mask 位 isfilter表示是否过滤
-(void)lockLabelWithPassword:(NSString *)password MMBstr:(NSString *)MMBstr MSAstr:(NSString *)MSAstr MDLstr:(NSString *)MDLstr MDdata:(NSString *)MDdata ldStr:(NSString *)ldStr isfilter:(BOOL)isfilter;//Lock标签

//KP 为标签的 KillPwd 值;MMB 为启动过滤操作的 bank 号，0x01 表 示 EPC，0x02 表示 TID，0x03 表示 USR，其他值为非法值;MSA 为启动过滤 操作的起始地址，单位为 bit;MDL为启动过滤操作的过滤数据长度，单位为 bit， 0x00 表示无过滤;MData 为启动过滤时的数据，单位为字节，若 MDL 不足整数 倍字节，不足位低位补 0;当标签的 KillPwd 区的值为 0x00000000 时，标签会忽 略 kill 命令，kill 命令不会成功 isfilter表示是否过滤
-(void)killLabelWithPassword:(NSString *)password MMBstr:(NSString *)MMBstr MSAstr:(NSString *)MSAstr MDLstr:(NSString *)MDLstr MDdata:(NSString *)MDdata isfilter:(BOOL)isfilter;//kill标签

-(void)getLabMessage;//获取标签数据 可以
-(void)setSM4PassWordWithmodel:(NSString *)model password:(NSString *)password originPass:(NSString *)originPass;//设置密钥   可以
-(void)getSM4PassWord;//获取密钥 可以

-(void)encryptionPassWordwithmessage:(NSString *)message;//SM4数据加密  可以
-(void)decryptPassWordwithmessage:(NSString *)message;//SM4数据解密  可以

-(void)encryptionUSERWithaddress:(NSString *)address lengthStr:(NSString *)lengthStr dataStr:(NSString *)dataStr;//USER加密  可以
-(void)decryptUSERWithaddress:(NSString *)address lengthStr:(NSString *)lengthStr;//USER解密 可以


-(void)enterUpgradeMode;//进入升级模式
-(void)enterUpgradeAcceptData;//进入升级接收数据
-(void)enterUpgradeSendtDataWith:(NSString *)dataStr;//进入升级发送数据
-(void)sendtUpgradeDataWith:(NSData *)dataStr;//发送升级数据

-(void)exitUpgradeMode;//退出升级模式


- (void)setFatScaleBluetoothDelegate:(id<FatScaleBluetoothManager>)delegate;
- (void)setPeripheralAddDelegate:(id<PeripheralAddDelegate>)delegate;
- (void)bleDoScan;
- (void)connectPeripheral:(CBPeripheral *)peripheral macAddress:(NSString *)macAddress;


- (Byte )getBye8:(Byte[])data;
- (void)sendDataToBle:(NSData *)data;


@end
