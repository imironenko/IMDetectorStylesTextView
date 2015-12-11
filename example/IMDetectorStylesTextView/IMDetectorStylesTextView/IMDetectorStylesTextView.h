//
//  IMDetectorStylesTextView.h
//
//  Created by Ihar Mironenka on 10/12/15.
//  Copyright © 2015 Ihar Mironenka. All rights reserved.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//	SOFTWARE.

#import <UIKit/UIKit.h>

@class IMDetectorStylesTextView;
@class IMDetectorEntity;

typedef NS_ENUM (int, IMDetectorType) {
	IMDetectorTypeNone = 0,
	IMDetectorTypeHashtag = 1 << 1,
	IMDetectorTypeMention = 1 << 2,
	IMDetectorTypeLink = 1 << 3,
	IMDetectorTypeAll = IMDetectorTypeHashtag | IMDetectorTypeMention | IMDetectorTypeLink
};

typedef void (^IMDetectorStylesHandler)(IMDetectorStylesTextView *textView, IMDetectorEntity *detectorEntity);

@interface IMDetectorStylesTextView : UITextView

@property (nonatomic) IMDetectorType detectorTypes; // default IMDetectorTypeNone
@property (nonatomic, copy) IMDetectorStylesHandler handler;
@property (nonatomic, strong, readonly) NSArray *entities;

- (void)setStylesForDetectorType:(IMDetectorType)detectorType normalStateAttributes:(NSDictionary *)normalAttributes highlightStateAttributes:(NSDictionary *)highlightAttributes;

// after setting a new text in the text view the attributes of this substring will be removed
- (void)setDetectorEntity:(IMDetectorEntity *)entity forSubstring:(NSString *)substring;
// after setting a new text in the text view the attributes of this range will be removed
- (void)setDetectorEntity:(IMDetectorEntity *)entity forRange:(NSRange)range;

- (NSArray *)entitiesForDetecorType:(IMDetectorType)detectorType;

@end

@interface IMDetectorEntity : NSObject

@property (nonatomic) NSRange range;

- (instancetype)initWithRange:(NSRange)range;
+ (instancetype)entityWithRange:(NSRange)range;

+ (IMDetectorType)detectorType;

@end

@interface IMDetectorHashtagEntity : IMDetectorEntity

@property (nonatomic, strong) NSString *text;

- (instancetype)initWithText:(NSString *)text range:(NSRange)range;
+ (instancetype)hashtagEntityWithText:(NSString *)text range:(NSRange)range;

@end

@interface IMDetectorMentionEntity : IMDetectorEntity

@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *userId;

- (instancetype)initWithDisplayName:(NSString *)displayName name:(NSString *)name userId:(NSString *)userId range:(NSRange)range;
+ (instancetype)mentionEntityWithDisplayName:(NSString *)displayName name:(NSString *)name userId:(NSString *)userId range:(NSRange)range;
+ (instancetype)mentionEntityWithDisplayName:(NSString *)displayName range:(NSRange)range;

@end

@interface IMDetectorLinkEntity : IMDetectorEntity

@property (nonatomic, strong) NSString *displayURL;
@property (nonatomic, strong) NSURL *url;

- (instancetype)initWithDisplayURL:(NSString *)displayURL url:(NSURL *)link range:(NSRange)range;
+ (instancetype)linkEntityWithDisplayURL:(NSString *)displayURL url:(NSURL *)link range:(NSRange)range;
+ (instancetype)linkEntityWithDisplayURL:(NSString *)displayURL range:(NSRange)range;

@end
