//
//  SourceEditorCommand.m
//  XCCodeDeclaration
//
//  Created by Jacue on 2017/8/1.
//  Copyright © 2017年 Jacue. All rights reserved.
//

#import "SourceEditorCommand.h"

typedef SourceEditorCommand * (^EditorBlock)(void);

@interface SourceEditorCommand ()

@property (nonatomic,weak) EditorBlock alignedByAnnotations;
@property (nonatomic,weak) EditorBlock alignedByEqual;
@property (nonatomic,weak) EditorBlock alignedByAt;
@property (nonatomic,weak) EditorBlock alignedByStar;
// 选中的要编辑的文本区域
@property (nonatomic,strong)XCSourceEditorCommandInvocation *invocation;

@end

@implementation SourceEditorCommand

- (void)performCommandWithInvocation:(XCSourceEditorCommandInvocation *)invocation completionHandler:(void (^)(NSError * _Nullable nilOrError))completionHandler{
    // Implement your command here, invoking the completion handler when done. Pass it nil on success, and an NSError on failure.
    
    self.invocation = invocation;

    XCSourceTextRange *selection = invocation.buffer.selections.firstObject;
    NSInteger index = selection.start.line;
    NSString *text = invocation.buffer.lines[index];
    
    if ([invocation.commandIdentifier isEqualToString:@"Base64.SourceEditorCommand"]) {
        
        NSString *insertBase64String = [NSString stringWithFormat:@"/*%@*/",Base64Encode(text)];
        NSMutableString *mutableString = [NSMutableString stringWithString:text];
        [mutableString insertString:insertBase64String atIndex:selection.start.column];
        invocation.buffer.lines[index] = mutableString;
        
    }else if ([invocation.commandIdentifier isEqualToString:@"Unicode.SourceEditorCommand"]){
        
        NSString *insertBase64String = [NSString stringWithFormat:@"/*%@*/",StringFromUnicode(text)];
        NSMutableString *mutableString = [NSMutableString stringWithString:text];
        [mutableString insertString:insertBase64String atIndex:selection.start.column];
        invocation.buffer.lines[index] = mutableString;
        
    }else if ([invocation.commandIdentifier isEqualToString:@"Alignment.SourceEditorCommand"]){
        
        self.alignedByAt().alignedByStar().alignedByEqual().alignedByAnnotations();
        
    }else if ([invocation.commandIdentifier isEqualToString:@"Getter.SourceEditorCommand"]){
        
        NSUInteger classNameBeginIndex = [text rangeOfString:@")"].location;
        NSUInteger classNameEndIndex = [text rangeOfString:@"*"].location;
        NSString *className = [[text substringWithRange:NSMakeRange(classNameBeginIndex + 1, classNameEndIndex - classNameBeginIndex - 1)]
                               stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        NSUInteger propertyNameEndIndex = [text rangeOfString:@";"].location;
        NSString *propertyName = [[text substringWithRange:NSMakeRange(classNameEndIndex + 1, propertyNameEndIndex - classNameEndIndex - 1)]
                               stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        for (NSString *str in invocation.buffer.lines) {
            
            if ([str rangeOfString:@"#pragma mark - Getter"].location != NSNotFound) {
                
                NSUInteger insertIndex = [invocation.buffer.lines indexOfObject:str] + 1;

                NSArray *lazyLoadCode = [self lazyLoadCodeWithClassName:className propertyName:propertyName];
                
                NSArray *reversedArray = [[lazyLoadCode reverseObjectEnumerator] allObjects];
                
                [reversedArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    [invocation.buffer.lines insertObject:obj atIndex:insertIndex];
                }];
                
                break;
            }
        }
    }
    
    completionHandler(nil);
}

#pragma mark ----------------------------  private ----------------------------

/**
 按注释的“//”对齐
 */
- (EditorBlock)alignedByAnnotations {
    
    return ^{

        [self alignedBy:@"//"];
        
        return self;
    };
}


/**
 按“=”对齐
 */
- (EditorBlock)alignedByEqual {
    
    return ^ {
        
        [self alignedBy:@"="];
        
        return self;
    };
}


/**
 按“@”对齐
 */
- (EditorBlock)alignedByAt {
    
    return ^ {
        
        [self alignedBy:@"@"];
        
        return self;
    };
}

/**
 按“*”对齐
 */
- (EditorBlock)alignedByStar {
    
    return ^ {
        
        [self alignedBy:@"*"];
        
        return self;
    };
}


/**
 根据某个标志符进行对齐

 @param identifier 标志符
 */
- (void)alignedBy:(NSString *)identifier {
    
    XCSourceTextRange *selection = self.invocation.buffer.selections.firstObject;
    NSInteger startLine = selection.start.line;
    NSInteger endLine = selection.end.line;
    
    // 需对齐的 identifier 位置，以最远的为参考位置对齐
    NSUInteger alignedIndex = 0;
    for (NSInteger index = startLine; index <= endLine; index ++) {
        
        NSString *text = self.invocation.buffer.lines[index];
        NSUInteger location = [text rangeOfString:identifier].location;
        if (location > alignedIndex && location != NSNotFound) {
            alignedIndex = location;
        }
    }
    
    for (NSInteger index = startLine; index <= endLine; index ++) {
        
        NSString *text = self.invocation.buffer.lines[index];
        NSUInteger location = [text rangeOfString:identifier].location;
        
        if (location != NSNotFound) {
            self.invocation.buffer.lines[index] = [self string:text insertSpaceAtIndex:location count:alignedIndex - location];
        }
    }

}


/**
 获取懒加载的代码数组（按行切割）

 @param clsName 类名
 @param property 属性名
 @return 懒加载的代码
 */
- (NSArray<NSString *> *)lazyLoadCodeWithClassName:(NSString *)clsName propertyName:(NSString *)property {
    
    NSString *lazyLoadString = [NSString stringWithFormat:@"\n- (%@ *)%@ {\n\t if (!_%@) {\n\t _%@ = [[%@ alloc] init];\n\t }\n\t return _%@;\n}\n",clsName,property,property,property,clsName,property];
    
    NSArray<NSString *> *lazyLoadCode = [lazyLoadString componentsSeparatedByString:@"\n"];
    
    return lazyLoadCode;
}

#pragma mark ----------------------------  functions ----------------------------

/**
 Unicode转中文
 */
static inline NSString *StringFromUnicode(NSString *TransformUnicodeString){
    
    NSString*tepStr1 = [TransformUnicodeString stringByReplacingOccurrencesOfString:@"\\u"withString:@"\\U"];
    NSString*tepStr2 = [tepStr1 stringByReplacingOccurrencesOfString:@"\""withString:@"\\\""];
    NSString*tepStr3 = [[@"\"" stringByAppendingString:tepStr2]stringByAppendingString:@"\""];
    NSData*tepData = [tepStr3 dataUsingEncoding:NSUTF8StringEncoding];
    NSString*axiba = [NSPropertyListSerialization propertyListWithData:tepData
                                                               options:NSPropertyListMutableContainers
                                                                format:NULL
                                                                 error:NULL];
    return [axiba stringByReplacingOccurrencesOfString:@"\\r\\n"withString:@"\n"];
}


/**
 Base64编码
 */
static inline NSString *Base64Encode(NSString *string) {
    NSData *encodedData = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [encodedData base64EncodedStringWithOptions:0];
}


/**
 插入指定位置、指定数量的空字符串

 @param text 输入的字符串
 @param index 插入位置
 @param count 插入空字符串的数量
 @return 带有字符串的输出结果
 */
- (NSMutableString *)string:(NSString *)text insertSpaceAtIndex:(NSUInteger)index count:(NSInteger)count {
    
    NSMutableString *mutableString = [NSMutableString stringWithString:text];
    // 生成中间填充的空格字符串
    NSString *spaceString = [@"" stringByPaddingToLength:count withString:@" " startingAtIndex:0];
    // 插入空格字符串
    [mutableString insertString:spaceString atIndex:index];
    
    return mutableString;
}


@end
