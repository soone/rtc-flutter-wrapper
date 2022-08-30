//
//  RCRTCIWRect.h
//  RongRTCLibWrapper
//
//  Created by RongCloud on 7/19/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RCRTCIWRect : NSObject

/*!
 水印 x 坐标 取值范围 0~1 浮点数。
 */
@property (nonatomic, assign) NSInteger x;

/*!
 水印 y 坐标 取值范围 0~1 浮点数。
 */
@property (nonatomic, assign) NSInteger y;

/*!
 水印的宽度
 */
@property (nonatomic, assign) NSInteger width;

@end

NS_ASSUME_NONNULL_END
