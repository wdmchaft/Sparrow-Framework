//
//  BenchmarkScene.m
//  Demo
//
//  Created by Daniel Sperl on 18.09.09.
//  Copyright 2009 Incognitek. All rights reserved.
//

#import "BenchmarkScene.h"
#import <QuartzCore/QuartzCore.h> // for CACurrentMediaTime()

@interface BenchmarkScene ()

- (void)addTestObject;
- (void)benchmarkComplete;

@end

#define WAIT_TIME 0.1f

@implementation BenchmarkScene

- (id)init
{
    if (self = [super init])
    {
        mAtlas = [[SPTextureAtlas alloc] initWithContentsOfFile:@"atlas.xml"];   
        
        // the container will hold all test objects
        mContainer = [[SPSprite alloc] init];
        mContainer.touchable = NO; // we do not need touch events on the test objects -- thus, 
                                     // it is more efficient to disable them.
        [self addChild:mContainer atIndex:0];        
        [mContainer release];
        
        // we create a button that is used to start the benchmark.
        mStartButton = [[SPButton alloc] initWithUpState:[mAtlas textureByName:@"button_wide"] 
                                                    text:@"Start benchmark"];
        [mStartButton addEventListener:@selector(onStartButtonPressed:) atObject:self
                               forType:SP_EVENT_TYPE_TRIGGERED];
        mStartButton.x = 80;
        mStartButton.y = 20;
        [self addChild:mStartButton];
        [mStartButton release];        
        
        mJuggler = [[SPJuggler alloc] init];
        mStarted = NO;
        
        [self addEventListener:@selector(onEnterFrame:) atObject:self forType:SP_EVENT_TYPE_ENTER_FRAME];
    }
    return self;    
}

- (void)onEnterFrame:(SPEnterFrameEvent *)event
{    
    [mJuggler advanceTime:event.passedTime];    
    
    if (mStarted)
    {
        mElapsed += event.passedTime;
        ++mFrameCount;

        if (mFrameCount % mWaitFrames == 0)
        {
            float targetFPS = self.stage.frameRate;
            float realFPS = mWaitFrames / mElapsed;
            
            if (ceilf(realFPS) >= targetFPS)
            {
                mFailCount = 0;
                [self addTestObject];            
            }
            else 
            {
                ++mFailCount;                
                
                if (mFailCount > targetFPS / 3.0f)
                    mWaitFrames = 15; // slow down creation process to be more exact               
                if (mFailCount == targetFPS)
                    [self benchmarkComplete]; // target fps not reached for one complete second
            }

            mElapsed = mFrameCount = 0;
        }
    }
    
    for (SPDisplayObject *child in mContainer)    
        child.rotation += 0.05f;    
}

- (void)onStartButtonPressed:(SPEvent*)event
{
    NSLog(@"starting benchmark");
    
    mStartButton.enabled = NO;
    mStarted = YES;
    mFailCount = 0;
    mWaitFrames = 3;
    
    [mResultText removeFromParent];
    mResultText = nil;
    
    mFrameCount = 0;
}

- (void)benchmarkComplete
{
    mStarted = NO;
    mStartButton.enabled = YES;
    [mJuggler removeAllObjects];
    
    NSLog(@"benchmark complete!");
    NSLog(@"fps: %d", self.stage.frameRate);
    NSLog(@"number of objects: %d", mContainer.numChildren);
    
    NSString *resultString = [NSString stringWithFormat:@"Result:\n%d objects\nwith %.1f fps", 
                              mContainer.numChildren, self.stage.frameRate]; 
    
    mResultText = [SPTextField textFieldWithWidth:250 height:200 text:resultString];
    mResultText.fontSize = 30;
    mResultText.color = 0xffffff;
    mResultText.x = (320 - mResultText.width) / 2;
    mResultText.y = (480 - mResultText.height) / 2;
    
    [self addChild:mResultText];
    
    while (mContainer.numChildren > 0)
        [mContainer removeChildAtIndex:0];    
}

float getRandomNumber()
{
    return (float) arc4random() / UINT_MAX;
}

- (void)addTestObject
{
    SPSprite *sprite = [[SPSprite alloc] init];
    int border = 15;
    sprite.x = border + getRandomNumber() * 320 - 2*border;
    sprite.y = border + getRandomNumber() * 480 - 2*border;
    
    SPImage *moon = [[SPImage alloc] initWithTexture:[mAtlas textureByName:@"moon"]];        
    moon.scaleX = moon.scaleY = 0.3f;
    moon.x = -moon.width/2 + 25;
    moon.y = -moon.height / 2;
    
    [sprite addChild:moon];
    [moon release];
    
    sprite.alpha = 0.0f;
    SPTween *fadeIn = [[SPTween alloc] initWithTarget:sprite time:0.25];
    [fadeIn animateProperty:@"alpha" targetValue:1.0f];
    [mJuggler addObject:fadeIn];
    [fadeIn release];
    
    [mContainer addChild:sprite];
    [sprite release];
}

- (void)dealloc
{
    [self removeEventListenersAtObject:self forType:SP_EVENT_TYPE_ENTER_FRAME];
    [mStartButton removeEventListenersAtObject:self forType:SP_EVENT_TYPE_TRIGGERED];

    [mJuggler release];
    [mAtlas release];
    [super dealloc];
}

@end
