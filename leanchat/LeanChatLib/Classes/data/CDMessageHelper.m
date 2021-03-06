//
//  CDMessageHelper.m
//  LeanChatLib
//
//  Created by lzw on 15/6/30.
//  Copyright (c) 2015年 LeanCloud（Bug汇报：QQ1356701892）.  All rights reserved.
//

#import "CDMessageHelper.h"
#import "CDChatManager.h"
#import "CDEmotionUtils.h"
#import "AVIMEmotionMessage.h"

@interface CDMessageHelper ()

@property (nonatomic, strong) NSCache *attributedStringCache;

@end

@implementation CDMessageHelper

+ (CDMessageHelper *)helper {
    static dispatch_once_t token;
    static CDMessageHelper *messageHelper;
    dispatch_once(&token, ^{
        messageHelper = [[CDMessageHelper alloc] init];
    });
    return messageHelper;
}

#pragma mark - message

- (NSString *)getMessageTitle:(AVIMTypedMessage *)msg {
    NSString *title;
    AVIMLocationMessage *locationMsg;
    switch (msg.mediaType) {
        case kAVIMMessageMediaTypeText:
            title = [CDEmotionUtils emojiStringFromString:msg.text];
            break;
            
        case kAVIMMessageMediaTypeAudio:
            title = @"声音";
            break;
            
        case kAVIMMessageMediaTypeImage:
            title = @"图片";
            break;
            
        case kAVIMMessageMediaTypeLocation:
            locationMsg = (AVIMLocationMessage *)msg;
            title = locationMsg.text;
            break;
        case kAVIMMessageMediaTypeEmotion:
            title = @"表情";
            break;
        case kAVIMMessageMediaTypeVideo:
            title = @"视频";
        default:
            break;
    }
    return title;
}

- (NSAttributedString *)attributedStringWithMessage:(AVIMTypedMessage *)message conversation:(AVIMConversation *)conversation {
    NSString *title = [self getMessageTitle:message];
    if (conversation.type == CDConversationTypeGroup) {
        id<CDUserModelDelegate> user = [[CDChatManager manager].userDelegate getUserById:message.clientId];
        title = [NSString stringWithFormat:@"%@: %@", user.username, title];
    }
    if (conversation.muted && conversation.unreadCount > 0) {
        title = [NSString stringWithFormat:@"[%ld条] %@", conversation.unreadCount, title];
    }
    NSString *mentionText = @"[有人@你] ";
    NSString *finalText;
    if (conversation.mentioned) {
        finalText = [NSString stringWithFormat:@"%@%@", mentionText, title];
    } else {
        finalText = title;
    }
    if (finalText == nil) {
        finalText = @"";
    }
    if ([self.attributedStringCache objectForKey:finalText]) {
        return [self.attributedStringCache objectForKey:finalText];
    }
    UIFont *font = [UIFont systemFontOfSize:13];
    NSDictionary *attributes = @{NSForegroundColorAttributeName: [UIColor grayColor], (id)NSFontAttributeName:font};
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:finalText attributes:attributes];
    
    if (conversation.mentioned) {
        NSRange range = [finalText rangeOfString:mentionText];
        [attributedString setAttributes:@{NSForegroundColorAttributeName:[UIColor colorWithRed:183/255.0 green:20/255.0 blue:20/255.0 alpha:1], NSFontAttributeName : font} range:range];
    }
    
    [self.attributedStringCache setObject:attributedString forKey:finalText];
    
    return attributedString;
}

//兼容安卓
+ (void)convertAndroidAttributesToIos:(AVIMTypedMessage *)message {
    id msg_data = message.attributes[@"msg_data"];
    if ([msg_data isKindOfClass:[NSString class]]) {
        NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:message.attributes];
        NSArray *dataArr = [NSJSONSerialization JSONObjectWithData:[msg_data dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
        attributes[@"msg_data"] = dataArr;
        message.attributes = attributes;
    }
}

@end
