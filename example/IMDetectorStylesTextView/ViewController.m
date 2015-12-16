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

	// disable the UITextView selectable and editable properties
	self.textView.selectable = NO;
	self.textView.editable = NO;

	// define an attributed string
	NSString *text = @"Lorem ipsum dolor sit er elit lamet, consectetaur cillium adipisicing pecu, #sed do eiusmod tempor #incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. @Duis #aute irure dolor in reprehenderit in voluptate velit esse cillum http://dolore.com eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, https://sunt.com/dsda in culpa qui officia deserunt mollit anim id est laborum. @Nam liber te conscient to factor tum poen legum #odioque civiuda.";

	NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:14.]};
	self.textView.attributedText = [[NSAttributedString alloc] initWithString:text attributes:attributes];

	// set the types of data
	[self.textView setDetectorTypes:IMDetectorTypeAll];

	// change styles
	[self.textView setStylesForDetectorType:IMDetectorTypeHashtag
					  normalStateAttributes:@{NSForegroundColorAttributeName: [UIColor brownColor]}
				   highlightStateAttributes:@{NSForegroundColorAttributeName: [UIColor purpleColor]}];
	[self.textView setStylesForDetectorType:IMDetectorTypeMention
					  normalStateAttributes:@{NSForegroundColorAttributeName: [UIColor cyanColor]}
				   highlightStateAttributes:@{NSForegroundColorAttributeName: [UIColor greenColor]}];

	// add link
	NSRange range = NSMakeRange(6, 5);
	IMDetectorLinkEntity *linkEntity = [IMDetectorLinkEntity linkEntityWithDisplayURL:@"ipsum"
																				  url:[NSURL URLWithString:@"http://ipsum.com"]
																				range:range];
	[self.textView setDetectorEntity:linkEntity forRange:range];

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

- (IBAction)hashtagStylesButtonPressed:(UIButton *)sender {
	[self.textView setStylesForDetectorType:IMDetectorTypeHashtag
					  normalStateAttributes:@{NSForegroundColorAttributeName: sender.backgroundColor, NSFontAttributeName: sender.titleLabel.font}
				   highlightStateAttributes:@{NSForegroundColorAttributeName: sender.tintColor}];
}

- (IBAction)linkStylesButtonPressed:(UIButton *)sender {
	[self.textView setStylesForDetectorType:IMDetectorTypeLink
					  normalStateAttributes:@{NSForegroundColorAttributeName: sender.backgroundColor, NSFontAttributeName: sender.titleLabel.font}
				   highlightStateAttributes:@{NSForegroundColorAttributeName: sender.tintColor}];
}

- (IBAction)mentionStylesButtonPressed:(UIButton *)sender {
	[self.textView setStylesForDetectorType:IMDetectorTypeMention
					  normalStateAttributes:@{NSForegroundColorAttributeName: sender.backgroundColor, NSFontAttributeName: sender.titleLabel.font}
				   highlightStateAttributes:@{NSForegroundColorAttributeName: sender.tintColor}];
}

@end
