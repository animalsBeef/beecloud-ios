//
//  BCApplePayAdapter.m
//  BCPay
//
//  Created by Ewenlong03 on 16/2/19.
//  Copyright © 2016年 BeeCloud. All rights reserved.
//

#import "BCApplePayAdapter.h"
#import "BeeCloudAdapterProtocol.h"
#import "UPAPayPlugin.h"
#import <PassKit/PassKit.h>

@interface BCApplePayAdapter ()<BeeCloudAdapterDelegate, UPAPayPluginDelegate>

@end

@implementation BCApplePayAdapter

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static BCApplePayAdapter *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[BCApplePayAdapter alloc] init];
    });
    return instance;
}

- (BOOL)canMakeApplePayments {
    return [PKPaymentAuthorizationViewController canMakePaymentsUsingNetworks:@[PKPaymentNetworkChinaUnionPay]] ;
}

- (BOOL)applePay:(NSMutableDictionary *)dic {
    if ([self canMakeApplePayments]) {
        NSString *tn = [dic stringValueForKey:@"tn" defaultValue:@""];
        if (tn.isValid) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UPAPayPlugin startPay:tn mode:@"01" viewController:dic[@"viewController"] delegate:[BCApplePayAdapter sharedInstance] andAPMechantID:dic[@"apple_mer_id"]];
            });
            return YES;
        }
    }
    return NO;
}

#pragma mark - Implementation UnionPayDelegate

- (void)UPPayPluginResult:(NSString *)result {
    int errcode = BCErrCodeSentFail;
    NSString *strMsg = @"支付失败";
    if ([result isEqualToString:@"success"]) {
        errcode = BCErrCodeSuccess;
        strMsg = @"支付成功";
    } else if ([result isEqualToString:@"cancel"]) {
        errcode = BCErrCodeUserCancel;
        strMsg = @"支付取消";
    }
    
    BCPayResp *resp = (BCPayResp *)[BCPayCache sharedInstance].bcResp;
    resp.resultCode = errcode;
    resp.resultMsg = strMsg;
    resp.errDetail = strMsg;
    [BCPayCache beeCloudDoResponse];
}

- (void)UPAPayPluginResult:(UPPayResult *)payResult {
    int errcode = BCErrCodeSentFail;
    NSString *strMsg = @"支付失败";
    
    switch (payResult.paymentResultStatus) {
        case UPPaymentResultStatusSuccess: {
            strMsg = @"支付成功";
            errcode = BCErrCodeSuccess;
            break;
        }
        case UPPaymentResultStatusFailure:
            break;
        case UPPaymentResultStatusCancel: {
            strMsg = @"支付取消";
            break;
        }
        case UPPaymentResultStatusUnknownCancel: {
            strMsg = @"支付取消,交易已发起,状态不确定,商户需查询商户后台确认支付状态";
            break;
        }
    }
    
    BCPayResp *resp = (BCPayResp *)[BCPayCache sharedInstance].bcResp;
    resp.resultCode = errcode;
    resp.resultMsg = strMsg;
    resp.errDetail = payResult.errorDescription;
    resp.paySource = @{@"otherInfo": payResult.otherInfo.isValid?payResult.otherInfo:@""};
    [BCPayCache beeCloudDoResponse];
    
}

@end
