//
//  ViewController.m
//  FaceTracking
//
//  Created by Ibrahima KH GUEYE on 01/07/2018.
//  Copyright © 2018 Ibrahima KH GUEYE. All rights reserved.
//

#import "ViewController.h"
#import <ARKit/ARKit.h>
#import <Vision/Vision.h>
@interface ViewController ()<ARSCNViewDelegate>

@property (weak, nonatomic) IBOutlet ARSCNView *arsSCNView;
@property (strong, nonatomic) NSMutableArray *scanFacesView;
@end

@implementation ViewController

-(void)viewWillAppear:(BOOL)animated {
    ARWorldTrackingConfiguration *arWorldConf = [[ARWorldTrackingConfiguration alloc] init];
    [self.arsSCNView.session  runWithConfiguration:arWorldConf];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _scanFacesView = [[NSMutableArray alloc] init];
    self.arsSCNView.delegate = self;
    BOOL isSupportedAr = [ARConfiguration isSupported];
    NSLog(isSupportedAr ? @"Yes" : @"No");
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(scanFaces) userInfo:nil repeats:YES];
}

-(CGRect)faceFrame: (CGRect)box {
    CGPoint origin = CGPointMake(CGRectGetMidX(box) * CGRectGetWidth(self.arsSCNView.bounds), (1 - CGRectGetMaxY(box)) * CGRectGetHeight(self.arsSCNView.bounds));
    CGSize size = CGSizeMake(CGRectGetWidth(box) * CGRectGetWidth(self.arsSCNView.bounds), CGRectGetHeight(box) * CGRectGetHeight(self.arsSCNView.bounds));
    
    CGRect cgRect = CGRectMake(origin.x, origin.y, size.width, size.height);
    return cgRect;
}

-(void)scanFaces {
    for (UIView *view in self.scanFacesView) {
        [view removeFromSuperview];
    }
    [self.scanFacesView removeAllObjects];
    CVPixelBufferRef capturedImage = [[self.arsSCNView.session currentFrame] capturedImage];
    CIImage *image = [[CIImage alloc] initWithCVPixelBuffer:capturedImage];
    VNDetectFaceRectanglesRequest *faceRectangleRequest = [[VNDetectFaceRectanglesRequest alloc] initWithCompletionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", [error localizedDescription]);
        }
        id faces = request.results;
        for (VNFaceObservation *face in faces) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIView *faceView =  [[UIView alloc] initWithFrame:[self faceFrame:face.boundingBox]];
                [faceView.layer setBorderColor:UIColor.redColor.CGColor];
                faceView.layer.borderWidth = 3.0;
                [self.arsSCNView addSubview:faceView];
                [self.scanFacesView addObject:faceView];
            });
            
        }
    }];
    
    NSDictionary<VNImageOption,id> *dict;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       NSArray<VNRequest *>* requestsTrack = [NSArray arrayWithObjects:faceRectangleRequest, nil];
       VNImageRequestHandler *vnImageRequest =  [[VNImageRequestHandler alloc] initWithCIImage:image orientation:[self deviceOrientation] options:dict];
        [vnImageRequest performRequests:requestsTrack  error:nil];
    });
}

-(CGImagePropertyOrientation)deviceOrientation {
    switch ([UIDevice currentDevice].orientation) {
        case UIDeviceOrientationPortrait:
            return kCGImagePropertyOrientationRight;
            break;
        case UIDeviceOrientationLandscapeRight:
            return kCGImagePropertyOrientationDown;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            return kCGImagePropertyOrientationLeft;
            break;
        case UIDeviceOrientationLandscapeLeft:
            return kCGImagePropertyOrientationUp;
            break;
        case UIDeviceOrientationUnknown:
            return kCGImagePropertyOrientationRight;
            break;
        default:
            return kCGImagePropertyOrientationRight;
            break;
    
    }
}
@end
