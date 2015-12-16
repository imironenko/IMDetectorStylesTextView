//
//  IMDetectorStylesTextView.m
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

#import "IMDetectorStylesTextView.h"

#pragma mark -

#define STYLE_TEXT_COLOR_DEFAULT			[UIColor blueColor]
#define STYLE_TEXT_COLOR_HIGHLIGHT_DEFAULT  [UIColor redColor]

NSString *const kIMDetectorTypeRegExp[IMDetectorTypeAll] = {
	[IMDetectorTypeHashtag]	= @"#\\w[[:alnum:]_]*",
	[IMDetectorTypeMention]	= @"@\\w[[:alnum:]_]*",
	[IMDetectorTypeLink]	= @"((mailto:|(news|(ht|f)tp(s?))://){1}\\S+)"
};

@interface IMDetectorStylesTextView()

@property (nonatomic, strong) NSMutableDictionary *attributesNormal;
@property (nonatomic, strong) NSMutableDictionary *attributesHighlight;

@property (nonatomic, strong) NSAttributedString *originalAttributedText;
/// @brief attributed text after parsing the specified types
@property (nonatomic, strong) NSAttributedString *backupAttributedText;
@property (nonatomic) IMDetectorEntity *activityEntity;

/// @brief value is subclass of IMDetectorEntity instance, key is NSRange
@property (nonatomic, strong) NSMutableDictionary *entitiesDictionary;

- (void)setStylesForDetectorTypes:(IMDetectorType)detectorTypes normalStateAttributes:(NSDictionary *)normalAttributes highlightStateAttributes:(NSDictionary *)highlightAttributes forseUpdatedStyles:(BOOL)isForseUpdatedStyles;
- (IMDetectorEntity *)detectorEntityForDetectorType:(IMDetectorType)detectorType withDisplayText:(NSString *)displayText range:(NSRange)range;
- (NSValue *)attributedTextRangeValueForPoint:(CGPoint)point;
- (void)configureNormalState;
- (NSDictionary *)attributesNormalForType:(IMDetectorType)detectorType;
- (NSDictionary *)attributesHighlightForType:(IMDetectorType)detectorType;

@end

@implementation IMDetectorStylesTextView

#pragma mark - Initialization

- (instancetype)init {
	if (self = [super init]) {
		[self setupDefaults];
	}

	return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		[self setupDefaults];
	}

	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self setupDefaults];
	}
	return self;
}

- (void)setupDefaults {
	self.entitiesDictionary = [[NSMutableDictionary alloc] init];
	self.attributesNormal = [[NSMutableDictionary alloc] init];
	self.attributesHighlight = [[NSMutableDictionary alloc] init];

	NSDictionary *styleNormalDefault = @{NSForegroundColorAttributeName: STYLE_TEXT_COLOR_DEFAULT};
	NSDictionary *styleHighlightDefault = @{NSForegroundColorAttributeName: STYLE_TEXT_COLOR_HIGHLIGHT_DEFAULT};

	[self setStylesForDetectorType:IMDetectorTypeAll normalStateAttributes:styleNormalDefault highlightStateAttributes:styleHighlightDefault];
}

#pragma mark - Public methods

- (void)setStylesForDetectorType:(IMDetectorType)detectorType normalStateAttributes:(NSDictionary *)normalAttributes highlightStateAttributes:(NSDictionary *)highlightAttributes {
	[self setStylesForDetectorTypes:detectorType normalStateAttributes:normalAttributes highlightStateAttributes:highlightAttributes forseUpdatedStyles:YES];
}

- (void)setDetectorEntity:(IMDetectorEntity *)entity forSubstring:(NSString *)substring {
	NSRange range = [self.attributedText.string rangeOfString:substring];
	entity.range = range;
	[self setDetectorEntity:entity forRange:range];
}

- (void)setDetectorEntity:(IMDetectorEntity *)entity forRange:(NSRange)range {
	NSAssert(entity, @"the entity parameter should not be nil");

	IMDetectorType type = [entity.class detectorType];

	NSAttributedString *originalAttributedText = self.attributedText;
	NSMutableAttributedString *mutableAttributedString = [originalAttributedText mutableCopy];
	[mutableAttributedString addAttributes:[self attributesNormalForType:type] range:range];

	[self.entitiesDictionary setObject:entity forKey:[NSValue valueWithRange:range]];

	self.attributedText = mutableAttributedString;
}

- (NSArray *)entitiesForDetecorType:(IMDetectorType)detectorType {
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(self.class.detectorType & %d) == %d", detectorType, detectorType];

	return [self.entities filteredArrayUsingPredicate:predicate];
}

#pragma mark - Overriden methods

- (void)setAttributedText:(NSAttributedString *)attributedText {
	BOOL isNewText = ![self.text isEqualToString:attributedText.string];
	[super setAttributedText:attributedText];

	if (isNewText) {
		self.originalAttributedText = attributedText;

		// update text styles (parsing #hashtag, @mentions and URLs)
		IMDetectorType currentType = self.detectorTypes;
		self.detectorTypes = currentType;
	}
}

- (void)setDetectorTypes:(IMDetectorType)detectorType {
	NSAttributedString *originalAttributedText = self.attributedText;

	if (!originalAttributedText || !self.attributesNormal || !self.attributesHighlight) {
		return;
	}

	NSMutableAttributedString *mutableAttributedString = [originalAttributedText mutableCopy];

	void(^wordsDetection)(IMDetectorType type, NSString *regexPattern) = ^void(IMDetectorType type, NSString *regexPattern) {
		NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:regexPattern
																		  options:NSRegularExpressionCaseInsensitive
																			error:nil];

		NSRange range = NSMakeRange(0, mutableAttributedString.length);

		[regex enumerateMatchesInString:mutableAttributedString.string options:kNilOptions range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {

			NSRange substringRange = [result rangeAtIndex:0];
			[mutableAttributedString addAttributes:[self attributesNormalForType:type] range:substringRange];

			NSString *substring = [mutableAttributedString attributedSubstringFromRange:substringRange].string;

			IMDetectorEntity *entity = [self detectorEntityForDetectorType:type withDisplayText:substring range:substringRange];
			[self.entitiesDictionary setObject:entity forKey:[NSValue valueWithRange:substringRange]];
		}];

	};

	wordsDetection(IMDetectorTypeHashtag, kIMDetectorTypeRegExp[IMDetectorTypeHashtag]);
	wordsDetection(IMDetectorTypeMention, kIMDetectorTypeRegExp[IMDetectorTypeMention]);
	wordsDetection(IMDetectorTypeLink, kIMDetectorTypeRegExp[IMDetectorTypeLink]);

	self.attributedText = mutableAttributedString;
}

- (void)setActivityEntity:(IMDetectorEntity *)activityEntity {
	// disable activity text if needed
	[self configureNormalState];

	_activityEntity = activityEntity;

	// set highlight state
	if (activityEntity) {
		NSRange range = [activityEntity range];

		NSMutableAttributedString *attributedString = [self.attributedText mutableCopy];

		IMDetectorType detectorType = [self.activityEntity.class detectorType];
		NSDictionary *highlightAttributes = [self attributesHighlightForType:detectorType];

		[attributedString addAttributes:highlightAttributes range:range];

		[UIView animateWithDuration:0.1  delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
			self.attributedText = attributedString;
		} completion:nil];
	}
}

- (NSArray *)entities {
	return [self.entitiesDictionary allValues];
}

#pragma mark - Event Handler

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	// store normal text
	self.backupAttributedText = self.attributedText;

	for (UITouch *touch in touches) {
		CGPoint touchPoint = [touch locationInView:self];
		NSValue *rangeValue = [self attributedTextRangeValueForPoint:touchPoint];

		self.activityEntity = self.entitiesDictionary[rangeValue];
	}
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	for (UITouch *touch in touches) {
		CGPoint touchPoint = [touch locationInView:self];
		NSValue *rangeValue = [self attributedTextRangeValueForPoint:touchPoint];

		self.activityEntity = self.entitiesDictionary[rangeValue];
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if (self.handler && self.activityEntity) {
		self.handler(self, self.activityEntity);
	}

	self.activityEntity = nil;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	if (self.handler && self.activityEntity) {
		self.handler(self, self.activityEntity);
	}

	self.activityEntity = nil;
}

#pragma mark - Private methods

- (void)setStylesForDetectorTypes:(IMDetectorType)detectorTypes normalStateAttributes:(NSDictionary *)normalAttributes highlightStateAttributes:(NSDictionary *)highlightAttributes forseUpdatedStyles:(BOOL)isForseUpdatedStyles {
	IMDetectorType types[3] = {IMDetectorTypeHashtag, IMDetectorTypeMention, IMDetectorTypeLink};

	for (NSInteger i = 0; i < 3; i++) {
		IMDetectorType type = types[i];

		if ((detectorTypes & type) == type) {
			NSArray *entities = [self entitiesForDetecorType:type];
			NSMutableAttributedString *mutableAttributedString = [self.attributedText mutableCopy];

			// remove the custom attributes, set origi
			for (IMDetectorEntity *entity in entities) {
				NSAttributedString *originalAttributedSubstring = [self.originalAttributedText attributedSubstringFromRange:entity.range];

				[mutableAttributedString replaceCharactersInRange:entity.range withAttributedString:originalAttributedSubstring];
			}

			// save new attributes
			[self.attributesNormal setObject:normalAttributes forKey:@(type)];
			[self.attributesHighlight setObject:highlightAttributes forKey:@(type)];

			// add the new attributes
			for (IMDetectorEntity *entity in entities) {
				[mutableAttributedString addAttributes:[self attributesNormalForType:type] range:entity.range];
			}

			if (isForseUpdatedStyles) {
				self.attributedText = mutableAttributedString;
			}
		}
	}
}

- (IMDetectorEntity *)detectorEntityForDetectorType:(IMDetectorType)detectorType withDisplayText:(NSString *)displayText range:(NSRange)range {
	IMDetectorEntity *entity;
	switch (detectorType) {
		case IMDetectorTypeHashtag:
			entity = [IMDetectorHashtagEntity hashtagEntityWithText:displayText range:range];
			break;
		case IMDetectorTypeMention:
			entity = [IMDetectorMentionEntity mentionEntityWithDisplayName:displayText range:range];
			break;
		case IMDetectorTypeLink:
			entity = [IMDetectorLinkEntity linkEntityWithDisplayURL:displayText range:range];
			break;
		default:
			break;
	}

	return entity;
}

- (NSValue *)attributedTextRangeValueForPoint:(CGPoint)point {
	NSLayoutManager *layoutManager = self.layoutManager;

	// find the tapped character location and compare it
	CGPoint locationOfTouch = point;
	locationOfTouch.x -= self.textContainerInset.left;
	locationOfTouch.y -= self.textContainerInset.top;

	NSInteger indexOfCharacter = [layoutManager characterIndexForPoint:locationOfTouch inTextContainer:self.textContainer fractionOfDistanceBetweenInsertionPoints:nil];

	for (NSValue *rangeValue in self.entitiesDictionary) {
		NSRange range = rangeValue.rangeValue;
		if (NSLocationInRange(indexOfCharacter, range)) {
			return rangeValue;
		}
	}

	return nil;
}

- (void)configureNormalState {
	if (self.backupAttributedText) {
		[UIView animateWithDuration:0.1  delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
			self.attributedText = self.backupAttributedText;
		} completion:nil];
	}
}

- (NSDictionary *)attributesNormalForType:(IMDetectorType)detectorType {
	return self.attributesNormal[@(detectorType)];
}

- (NSDictionary *)attributesHighlightForType:(IMDetectorType)detectorType {
	return self.attributesHighlight[@(detectorType)];
}

@end


#pragma mark -

@implementation IMDetectorEntity

- (instancetype)initWithRange:(NSRange)range {
	if (self = [super init]) {
		_range = range;
	}

	return self;
}

+ (instancetype)entityWithRange:(NSRange)range {
	return [[self alloc] initWithRange:range];
}

+ (IMDetectorType)detectorType {
	return IMDetectorTypeNone;
}

@end

#pragma mark -

@implementation IMDetectorHashtagEntity

- (instancetype)initWithText:(NSString *)text range:(NSRange)range {
	if (self = [super initWithRange:range]) {
		_text = text;
	}

	return self;
}

+ (instancetype)hashtagEntityWithText:(NSString *)text range:(NSRange)range {
	return [[self alloc] initWithText:text range:range];
}

+ (IMDetectorType)detectorType {
	return IMDetectorTypeHashtag;
}

@end

#pragma mark -

@implementation IMDetectorMentionEntity

- (instancetype)initWithDisplayName:(NSString *)displayName name:(NSString *)name userId:(NSString *)userId range:(NSRange)range {
	if (self = [super initWithRange:range]) {
		_displayName = displayName;
		_name = name;
		_userId = userId;
	}

	return self;
}

+ (instancetype)mentionEntityWithDisplayName:(NSString *)displayName name:(NSString *)name userId:(NSString *)userId range:(NSRange)range {
	return [[self alloc] initWithDisplayName:displayName name:name userId:userId range:range];
}

+ (instancetype)mentionEntityWithDisplayName:(NSString *)displayName range:(NSRange)range {
	return [self mentionEntityWithDisplayName:displayName name:nil userId:nil range:range];
}


+ (IMDetectorType)detectorType {
	return IMDetectorTypeMention;
}

@end

#pragma mark -

@implementation IMDetectorLinkEntity

- (instancetype)initWithDisplayURL:(NSString *)displayURL url:(NSURL *)link range:(NSRange)range {
	if (self = [super initWithRange:range]) {
		_displayURL = displayURL;
		_url = link;
	}

	return self;
}

+ (instancetype)linkEntityWithDisplayURL:(NSString *)displayURL url:(NSURL *)link range:(NSRange)range {
	return [[self alloc] initWithDisplayURL:displayURL url:link range:range];
}

+ (instancetype)linkEntityWithDisplayURL:(NSString *)displayURL range:(NSRange)range {
	return [self linkEntityWithDisplayURL:displayURL url:nil range:range];
}

+ (IMDetectorType)detectorType {
	return IMDetectorTypeLink;
}

@end
