//
//  ViewController.m
//  微信支付Demo
//
//  Created by liulianqi on 15/10/20.
//  Copyright © 2015年 sunxianglong. All rights reserved.
//

#import "ViewController.h"
#import "WXApi.h"
#import "payRequsestHandler.h"

@interface ViewController ()

@end

@implementation ViewController
 /*
1.往自己项目里集成，主要修改”payRequsestHandler.h“这些参数，换成自己申请的
2.看info设置图
3.info.plist加上以下配置
  ｛
  1.加一个“NSAppTransportSecurity“  字典类型  在字典里加一个“NSAllowsArbitraryLoads”  bool类型 设为 YES
  
  2.加一个“LSApplicationQueriesSchemes” 数组类型  数组里加一个“Item0”  字符串类型  字符串里“wechat”  用来判断微信客户端的，ios9新特效
  ｝
  
  #define APP_ID          @"wxa97033b65142f1e6"               //APPID
  #define APP_SECRET      @"22114779f1539ef3b87a8f0f63c5c950" //appsecret
  //商户号，填写商户对应参数
  #define MCH_ID          @"1228604401"
  //商户API密钥，填写相应参数
  #define PARTNER_ID      @"aadd1ca9e5ee5c0a68001712b08a5fbe"
  //支付结果回调页面

  
5，如果出现图片“微信支付只出现确定.jpg”这种情况  是点击后返回的状态竟然是-2，用户取消  造成原因如下
  ｛
  
  说几个可能出现问题的点。
  第一步获取prepayId，这一步往往都不会有什么错误，根着官方文档都不会出现什么问题，坑在第二步发送跳转
  
  
  1、注意一下 nonceStr 需要是第一步里生成的 nonceStr，而不是重新生成。
  
  
  
  2、sign 需要重新针对5个字段进行签名：partnerId prepayId package nonceStr timeStamp  不需要传入appid或者openid
  需要传入appid
  
  3、package = @"Sign=WXPay" 注意服务器传来的"="会不会被转义成 %3D
  
  
  4、sign的确需要大写，不像之前有些帖子说的要小写。
  
  最坑的是
  
  5，如果你用了友盟和微信SDK
  
  如果你app同时使用了友盟分享（含微信分享）和微信支付。如果你没有处理好这个两个SDK register的顺序，那就很不幸，也会出现这种情况。
  （如何出现这种情况，请看我的测试步骤：1、杀掉微信进程、2、删除自己开发的app、3、重新同步自己的app到设备，点击微信支付）
  两者register的顺序：如果是先调用微信registerApp、然后调用友盟的 [UMSocialWechatHandler setWXAppId:WXAppID appSecret:[NSString stringWithBundleNameForKey:@"WXAppSecret"] url:url] ，然后按照我测试的步骤，应该就会出现。
  解决办法：改变两者的register步骤。先调用友盟，然后调用微信。
  
  
  
  
  
  ｝
  */
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UIButton *button = [UIButton buttonWithType: UIButtonTypeCustom];
   
    button.frame = CGRectMake(0, 0, self.view.frame.size.width,self.view.frame.size.width*196/719 );
     button.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
    [button setBackgroundImage:[UIImage imageNamed:@"WePayLogo"] forState: UIControlStateNormal];
    [button addTarget:self action:@selector(wxpay) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}
#pragma mark -WX //微信支付
//微信支付
- (void)wxpay
{
    if (![WXApi isWXAppInstalled] && ![WXApi isWXAppSupportApi])
    {
        [self alert:@"提示" msg:@"请安装微信客户端"];
        return;
    }
    //{{{
    //本实例只是演示签名过程， 请将该过程在商户服务器上实现
    
    //创建支付签名对象
    payRequsestHandler *req = [[payRequsestHandler alloc] init];
    //初始化支付签名对象
    [req init:APP_ID mch_id:MCH_ID];
    //设置密钥
    [req setKey:PARTNER_ID];
    
    //}}}
    
    //获取到实际调起微信支付的参数后，在app端调起支付
    NSMutableDictionary *dict = [req sendPay_demo];
    
    if(dict == nil){
        //错误提示
        NSString *debug = [req getDebugifo];
        
        [self alert:@"提示信息" msg:debug];
        
        NSLog(@"%@\n\n",debug);
    }else{
        NSLog(@"%@\n\n",[req getDebugifo]);
        //[self alert:@"确认" msg:@"下单成功，点击OK后调起支付！"];
        
        NSMutableString *stamp  = [dict objectForKey:@"timestamp"];
        
        //调起微信支付
        PayReq* req             = [[PayReq alloc] init];
        req.openID              = [dict objectForKey:@"appid"];
        req.partnerId           = [dict objectForKey:@"partnerid"];
        req.prepayId            = [dict objectForKey:@"prepayid"];
        req.nonceStr            = [dict objectForKey:@"noncestr"];
        req.timeStamp           = stamp.intValue;
        req.package             = [dict objectForKey:@"package"];
        req.sign                = [dict objectForKey:@"sign"];
        
        [WXApi sendReq:req];
    }
}




-(void) onResp:(BaseResp*)resp
{
    NSString *strMsg = [NSString stringWithFormat:@"errcode:%d", resp.errCode];
    NSString *strTitle;
    
    NSDictionary *CodeDict = @{@"0":@"支付成功",@"-1":@"失败",@"-2":@"用户点击取消",@"-3":@"发送失败",@"-4":@"授权失败",@"-5":@"微信不支持"};
    
    if([resp isKindOfClass:[PayResp class]]){
        
        //支付返回结果，实际支付结果需要去微信服务器端查询
        strTitle = [NSString stringWithFormat:@"支付结果"];
        
        switch (resp.errCode) {
            case WXSuccess:
                strMsg = @"支付结果：成功！";
                [self alert:@"提示" msg:strMsg];
                break;
                
            default:
                
                strMsg = [NSString stringWithFormat:@"支付结果：%@！",[CodeDict valueForKey:[NSString stringWithFormat:@"%d",resp.errCode]]];
                [self alert:@"提示" msg:strMsg];
                
                
                break;
                
        }
    }
}

//客户端提示信息
- (void)alert:(NSString *)title msg:(NSString *)msg
{
    UIAlertView *alter = [[UIAlertView alloc] initWithTitle:title message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alter show];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
