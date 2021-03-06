//
//  ABSSimpleSession.m
//  CameraRtmpSDK
//
//  Created by Abson on 16/9/5.
//  Copyright © 2016年 Abson. All rights reserved.
//

#import "ABSSimpleSession.h"
#import "ABSPreviewView.h"
#import "CameraSource.h"
#import "H264Encode.h"

@interface ABSSimpleSession()
{
    dispatch_queue_t _graphManageQueue;
    PushSDK::Apple::CameraSource* m_cameraSource;
    PushSDK::ffmpeg::H264Encode* m_h264Encoder;
}
@property (nonatomic, assign) int bitrate;
@property (nonatomic, assign) CGSize videoSize;
@property (nonatomic, assign) int fps;
@property (nonatomic, assign) BOOL useInterfaceOrientation;
@property (nonatomic, strong) ABSPreviewView* previewView;
@property (nonatomic, assign) ABSCameraState cameraState;
@property (nonatomic, weak) UIView* preview;
@end

@implementation ABSSimpleSession
- (void)dealloc
{
    [self endSession];

    Cplus_Release(m_cameraSource);
    Cplus_Release(m_h264Encoder);
}


- (instancetype)initWithVideoSize:(CGSize)videoSize
                              fps:(int)fps
                          bitrate:(int)bps
          useInterfaceOrientation:(BOOL)useInterfaceOrientation
                      cameraState:(ABSCameraState)cameraState
                          previewFrame:(CGRect)previewFrame
{
    if (self = [super init]) {

        self.videoSize = videoSize;
        self.fps = fps;
        self.bitrate = bps;
        self.useInterfaceOrientation = useInterfaceOrientation;
        self.cameraState = cameraState;

        _previewView = [[ABSPreviewView alloc] initWithFrame:CGRectMake(0, 0, previewFrame.size.width, previewFrame.size.height)];

        _graphManageQueue = dispatch_queue_create("com.PushSDK.session.graph", DISPATCH_QUEUE_SERIAL);

        __weak typeof(self) bSelf = self;
//        dispatch_async(_graphManageQueue, ^{
            [bSelf setupGraph];
//        });
    }
    return self;
}

- (void)setupGraph
{
    m_cameraSource = new PushSDK::Apple::CameraSource();
    m_cameraSource->setupCamera(self.fps, (_cameraState == ABSCameraStateFront), true, AVCaptureSessionPreset640x480);
    CALayer* previeLayer = m_cameraSource->captureVideoPreviewLayer();
    previeLayer.frame = self.previewView.bounds;
    [self.previewView.layer addSublayer:previeLayer];
}

- (void)startRecord
{
    m_h264Encoder = new PushSDK::ffmpeg::H264Encode(self.videoSize.width, self.videoSize.height, self.fps, self.bitrate);
    m_cameraSource->setOutput(m_h264Encoder);
    m_cameraSource->startRecord();
}

- (void)endRecord
{
    [self endSession];
}

- (void)endSession
{
    m_cameraSource->stopRecord();

    // 确保 pushBuffer 方法已经编码完才调用
//    dispatch_queue_t cameraQueue = m_cameraSource->cameraRecordQueue();
   // dispatch_async(cameraQueue, ^{
    // dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    // });
//    });
}

@end
