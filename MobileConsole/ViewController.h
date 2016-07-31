//
//  ViewController.h
//  mobileconsole
//
//  Created by vsnRain on 26/04/2014.
//  Copyright (c) 2014 vsnRain. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UIBarPositioningDelegate>

@property (weak, nonatomic) IBOutlet UITextView *logView;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property (weak, nonatomic) IBOutlet UITextField *field;

@end
