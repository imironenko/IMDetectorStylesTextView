//
//  ViewController.m
//  IMDetectorStylesTextView
//
//  Created by Ihar Mironenka on 11/12/15.
//  Copyright © 2015 Ihar Mironenka. All rights reserved.
//

#import "ViewController.h"
#import "IMDetectorStylesTextView.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet IMDetectorStylesTextView *textView;

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	// set the types of data
	[self.textView setDetectorTypes:IMDetectorTypeAll];

	// change styles
	[self.textView setStylesForDetectorType:IMDetectorTypeHashtag normalStateAttributes:@{NSForegroundColorAttributeName: [UIColor brownColor]} highlightStateAttributes:@{NSForegroundColorAttributeName: [UIColor purpleColor]}];
	[self.textView setStylesForDetectorType:IMDetectorTypeMention normalStateAttributes:@{NSForegroundColorAttributeName: [UIColor cyanColor]} highlightStateAttributes:@{NSForegroundColorAttributeName: [UIColor greenColor]}];

	// add link
	NSRange range = NSMakeRange(6, 5);
	[self.textView setDetectorEntity:[IMDetectorLinkEntity linkEntityWithDisplayURL:@"ipsum" url:[NSURL URLWithString:@"http://ipsum.com"] range:range] forRange:range];

	// define a handler block
	[self.textView setHandler:^(IMDetectorStylesTextView *textView, IMDetectorEntity *detectorEntity){
		NSString *text = nil;
		switch ([detectorEntity.class detectorType]) {
			case IMDetectorTypeHashtag:
				text = [(IMDetectorHashtagEntity *)detectorEntity text];
				break;
			case IMDetectorTypeMention:
				text = [(IMDetectorMentionEntity *)detectorEntity displayName];
				break;

			case IMDetectorTypeLink:
				text = [(IMDetectorLinkEntity *)detectorEntity displayURL];
				break;

			default:
				break;
		}

		UIAlertController *controller = [UIAlertController alertControllerWithTitle:text message:nil preferredStyle:UIAlertControllerStyleAlert];
		[controller addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
		[self presentViewController:controller animated:YES completion:nil];
	}];

}

@end
