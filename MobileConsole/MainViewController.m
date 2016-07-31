//
//  ViewController.m
//  mobileconsole
//
//  Created by vsnRain on 26/04/2014.
//  Copyright (c) 2014 vsnRain. All rights reserved.
//

#import "MainViewController.h"

#include <asl.h>
#include <stdio.h>
#include <sys/un.h>
#include <sys/socket.h>
#include <unistd.h>
#include <poll.h>
#include <errno.h>

#define SV_SOCK_PATH "/private/var/run/lockdown/syslog.sock"

@interface MainViewController (){
    
    int socket_fd;
    char buffer[1024];
    
    //NSTimer *timer;
}

@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // ==================== UI ====================
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.navigationBar.bounds.size.height, 0.0, 0, 0);
    self.logView.contentInset = contentInsets;
    self.logView.scrollIndicatorInsets = contentInsets;
    
    // ==================== CONNECT SOCKET ====================
    
    socket_fd = socket(PF_UNIX, SOCK_STREAM, 0);
    if(socket_fd < 0){
        printf("socket() failed\n");
        //return 1;
    }
    
    struct sockaddr_un address;
    
    /* start with a clean address structure */
    memset(&address, 0, sizeof(struct sockaddr_un));
    
    address.sun_family = AF_UNIX;
    strncpy(address.sun_path, SV_SOCK_PATH, sizeof(address.sun_path)-1);
    
    long res = connect(socket_fd, (struct sockaddr *) &address, sizeof(struct sockaddr_un));
    
    if(res != 0){
        printf("connect() failed with error %s\n",strerror(errno));
        //return 1;
    }
    
    //fcntl(socket_fd, F_SETFL, O_NONBLOCK);
    
    // ==================== CONFIG LOG ====================
    [self aslCommand:"raw\n"];
    [self readPressed:nil];
    
    [self aslCommand:"watch\n"];
    //[self readPressed:nil];
    
    [self readThreadPressed:nil];
    
    // ==================== UPDATE TIMER ====================
    
    //timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(rebuildLog) userInfo:nil repeats:YES];
    //[timer fire];
}

- (void)closeSocket{
    close(socket_fd);
}

// ==================== LOG ====================

-(void) addToLog:(NSString *)string{
    self.logView.text = [NSString stringWithFormat:@"%@\n%@", self.logView.text, string];
    
    NSRange range = NSMakeRange(self.logView.text.length - 1, 1);
    [self.logView scrollRangeToVisible:range];
}

-(void)clearLog{
    self.logView.text = @"";
}

// ==================== ASL ====================

- (void)aslCommand:(const char *)command {
    long res = write(socket_fd, command, strlen(command));
    
    if ( res == -1) {
        NSLog(@"ERROR %d occured during command \"%s\" ", errno, command);
    }
}

- (IBAction)readPressed:(id)sender {
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //buffer[0] = '\0';
        memset (buffer, '\0', sizeof(buffer));
        long nbytes = read(socket_fd, buffer, sizeof(buffer));
        if (nbytes <= 0){
            //break;
        }
        buffer[nbytes] = '\0';
        
        NSString *logstring = [NSString stringWithFormat:@"%s", buffer];
        //[NSString stringWithUTF8String:buffer];
        NSLog(@"%@", logstring);
            
        //dispatch_sync(dispatch_get_main_queue(), ^{
        //    [self addToLog:logstring];
        //});
    //});
}

- (IBAction)readThreadPressed:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        struct pollfd pfd;
        unsigned char buf[16384];
        int n = 0;
        
        pfd.fd = socket_fd;
        pfd.events = POLLIN;
        
        while (pfd.fd != -1) {
            
            //memset(buf, '\0', sizeof(buf));
            
            n = poll(&pfd, 1, -1);
            if (n < 0) {
                close(socket_fd);
                perror("polling error");
                exit(1);
            }
            
            if (pfd.revents & POLLIN) {
                long n = read(socket_fd, buf, sizeof(buf));
                buf[n] = '\0';
                
                if (n < 0){
                    perror("read error");
                    exit(1); /* possibly not an error, just disconnection */
                }else if (n == 0) {
                    shutdown(socket_fd, SHUT_RD);
                    pfd.fd = -1;
                    pfd.events = 0;
                } else {
                    //NSLog(@"%s", buf);
                    NSString *logstring = [NSString stringWithUTF8String:buf];
                    
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [self addToLog:logstring];
                    });
                }
            }
        }
    });
    
    /*
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (true){
            //buffer[0] = '\0';
            memset(buffer, '\0', sizeof(buffer));
            long nbytes = read(socket_fd, buffer, sizeof(buffer));
            if (nbytes <= 0){
                break;
            }
            buffer[nbytes] = '\0';
            
            NSString *logstring = [NSString stringWithFormat:@"%s", buffer];
            //[NSString stringWithUTF8String:buffer];
            //NSLog(@"%@", logstring);
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self addToLog:logstring];
            });
        }
    });
    */
}

// ============================== OTHER ==============================

- (IBAction)itemPressed:(id)sender {
    UIBarButtonItem *btn = (UIBarButtonItem *) sender;
    
    const char *cmd = [self.field.text UTF8String];
    
    switch (btn.tag) {
        case 0:
            [self aslCommand:cmd];
            break;
        case 1:
            [self readPressed:nil];
            break;
        case 2:
            [self readThreadPressed:nil];
            break;
            
        default:
            break;
    }
}

- (UIBarPosition) positionForBar:(id <UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}

- (BOOL) prefersStatusBarHidden {
    return NO;
}

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewDidDisappear:(BOOL)animated{
    //[timer invalidate];
    //timer = nil;
    
    [self closeSocket];
}

@end
