//
//  DIYParallax.m
//  parallax
//
//  Created by Andrew Sliwinski on 6/1/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import "DIYParallax.h"

//

#define UPDATE_INTERVAL 1.0f/90
#define OFFSET_MULTIPLIER 60.0f

//

@interface DIYParallax ()
@property (nonatomic, retain) CMMotionManager *motionManager;
@property (nonatomic, retain) NSMutableArray *layers;
@end

//

@implementation DIYParallax

@synthesize layers;
@synthesize motionManager;

#pragma mark - Init

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Init layers object
        layers              = [[NSMutableArray alloc] init];
        
        // Init motion manager
        motionManager       = [[CMMotionManager alloc] init];
        motionManager.deviceMotionUpdateInterval = UPDATE_INTERVAL;
    }
    
    return self;
}

#pragma mark - Public methods

/**
 * Add layer to view.
 *
 * @param  int  Layer index
 * @param  NSString  Asset name
 * @param  CGPoint  X/Y position of layer
 *
 * @return  void
 */
- (void)addLayer:(CGFloat)depth imageNamed:(NSString *)asset frame:(CGRect)frame
{
    // Track layer
    [layers addObject:[NSNumber numberWithFloat:depth]];
    
    // Render to view
    UIImageView *item       = [[UIImageView alloc] initWithFrame:frame];
    NSString *bundlePath    = [[NSBundle mainBundle] bundlePath];
    UIImage *image          = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", bundlePath, asset]];
    item.image              = image;
    [self insertSubview:item atIndex:[layers count] - 1];
    
    [item release];
    [image release];
}

/**
 * Start listening to motion manager updates.
 *
 * @return  void
 */
- (void)startListening
{
    if ([self.motionManager isDeviceMotionAvailable])
    {
        __block BOOL referenceSet       = false;
        __block CGFloat referencePitch  = 0.0f;
        __block CGFloat referenceRoll   = 0.0f;
        //__block CGFloat referenceYaw    = 0.0f;
        
        [motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion *motion, NSError *error) {
            // Set reference angles
            if (!referenceSet)
            {
                referencePitch  = [[motion attitude] pitch];
                referenceRoll   = [[motion attitude] roll];
                //referenceYaw    = [[motion attitude] yaw];
                
                referenceSet    = true;
            }
            
            // Reference offset
            CGFloat _pitch      = [[motion attitude] pitch] - referencePitch;
            CGFloat _roll       = [[motion attitude] roll] - referenceRoll;
            //CGFloat _yaw        = [[motion attitude] yaw] - referenceYaw;
            
            // Update
            // @note Add orientation support here
            [self update:CGPointMake(_pitch, -_roll)];
        }];
    }
}

/**
 * Stops listening to the motion manager.
 *
 * @return  void
 */
- (void)stopListening
{
    if ([self.motionManager isDeviceMotionAvailable])
    {
        [motionManager stopDeviceMotionUpdates];
    }
    [motionManager release]; motionManager = nil;
}

#pragma mark - Private methods

/**
 * Loops through the layers array and applies subview x/y translations.
 *
 * @param  CGPoint  X/Y translation
 *
 * @returns  void
 */
- (void)update:(CGPoint)point
{
    for (int i = 0; i < [layers count]; i++)
    {
        // View
        UIView *view = [self.subviews objectAtIndex:i];
        
        // Calculate transformation
        CGFloat d = [[layers objectAtIndex:i] floatValue];
        CGFloat x = [self calculateTransformForAngle:point.x withDistance:d];
        CGFloat y = [self calculateTransformForAngle:point.y withDistance:d];
        
        // Translate
        view.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, OFFSET_MULTIPLIER * x, OFFSET_MULTIPLIER * y);
    }
}

/**
 * Calculates a transform using euler angle input and object distance.
 *
 * @param  CGFloat  Euler angle (radians)
 * @param  CGFloat  Distance
 *
 * @return  CGFloat
 */
- (double)calculateTransformForAngle:(double)angle withDistance:(double)distance
{
    return angle * distance;
}

#pragma mark - Dealloc

- (void)releaseObjects
{
    [motionManager release]; motionManager = nil;
    [layers release]; layers = nil;
}

- (void)dealloc
{    
    [self releaseObjects];
    [super dealloc];
}

@end