//
//  HelloWorldLayer.m
//  Snowboard
//
//  Created by Kyle Langille on 12-03-28.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//


// Import the interfaces
#import "HelloWorldLayer.h"
#import "CCParallaxNode-Extras.h"
#import "SimpleAudioEngine.h"
#import "CCGestureRecognizer.h"
#import "MainMenuScene.h"
#import "SettingsManager.h"
#import "StoreScene.h"
#import "PauseLayer.h"
#import "MoveSineAction.h"
#import "Flurry.h"

#define kNumTrees 30
#define kNumRocks 5
#define kNumSpikes 5 
#define kNumCliff 1
#define kNumCoins 10
#define kNumIce 5
#define kNumArches 5

// HelloWorldLayer implementation
@implementation HelloWorldLayer{
    
    float deadSpeed;
    bool equipAction;
    bool equipActionDone;
    
}

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
    if( (self=[super init])) {
        //Path get the path to MyTestList.plist
        NSString *path=[[NSBundle mainBundle] pathForResource:@"equipment" ofType:@"plist"];
        //Next create the dictionary from the contents of the file.
        equipmentDic = [NSDictionary dictionaryWithContentsOfFile:path];
        
        CCGestureRecognizer* recognizer;
        /*recognizer = [CCGestureRecognizer CCRecognizerWithRecognizerTargetAction:[[[UITapGestureRecognizer alloc]init] autorelease] target:self action:@selector(pause:)];
        [startButton addGestureRecognizer:recognizer];*/
        
        recognizer = [CCGestureRecognizer CCRecognizerWithRecognizerTargetAction:[[[UISwipeGestureRecognizer alloc]init] autorelease] target:self action:@selector(swipe)];
        ((UISwipeGestureRecognizer*)recognizer.gestureRecognizer).direction = UISwipeGestureRecognizerDirectionUp;
        [self addGestureRecognizer:recognizer];

        horzRecognizer = [CCGestureRecognizer CCRecognizerWithRecognizerTargetAction:[[[UISwipeGestureRecognizer alloc]init] autorelease] target:self action:@selector(swipeJump)];
        ((UISwipeGestureRecognizer*)horzRecognizer.gestureRecognizer).direction = UISwipeGestureRecognizerDirectionLeft || UISwipeGestureRecognizerDirectionRight;
        [self addGestureRecognizer:horzRecognizer];        
        
        if([[[SettingsManager sharedSettingsManager] getString:@"equipment"] isEqualToString:@"hammer"]){
            equipmentName = @"mjolnir";
        }else if([[[SettingsManager sharedSettingsManager] getString:@"equipment"] isEqualToString:@"sword"]){
            equipmentName = @"excalibur";
        }else if([[[SettingsManager sharedSettingsManager] getString:@"equipment"] isEqualToString:@"wings"]){
            equipmentName = @"icarus";
            [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"wings.plist"];
            CCSpriteBatchNode *wingSheet = [CCSpriteBatchNode batchNodeWithFile:@"wings.png"];
            [self addChild:wingSheet];
        }else if([[[SettingsManager sharedSettingsManager] getString:@"equipment"] isEqualToString:@"midas"]){
            equipmentName = @"midas";
        }else{
            equipmentName = @"none";
        }
        
        characterName = [[SettingsManager sharedSettingsManager] getString:@"character"];
        
        NSDictionary *purchaseParams =
        [NSDictionary dictionaryWithObjectsAndKeys:
         @"Character", characterName, // Capture user status
         @"Item", equipmentName,
         nil];
        
        [Flurry logEvent:@"Game Start Selections" withParameters:purchaseParams];
                
        hitTime = NO;
        fallen = NO;
        tapCount = 0;
        timer = 0;
        _started = NO;
        caught = NO;
        dead = NO;
        scoreFlipper = 0;
        bigJump = NO;
        hitJump = NO;
        tricker = NO;
        ySpeed = 0;
        equipAction = NO;
        equipActionDone = YES;
        self.isTouchEnabled = YES;
        icarus = NO;
        oneUse = NO;
        midas = NO;
        firstCliff = YES;
        paused = NO;
        jumped = NO;
        jumps = 0;
        wings = 0;
        chopper = 0;
        hammerbreak = 0;
        hammertime = 0;
        
        //Character Animations
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:[NSString stringWithFormat:@"%@turn.plist", characterName]];
        CCSpriteBatchNode *yetispriteSheet = [CCSpriteBatchNode batchNodeWithFile:[NSString stringWithFormat:@"%@turn.png", characterName]];
            [self addChild:yetispriteSheet];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:[NSString stringWithFormat:@"%@jumpright.plist", characterName]];
        CCSpriteBatchNode *jumpspriteSheet = [CCSpriteBatchNode batchNodeWithFile:[NSString stringWithFormat:@"%@jumpright.plist", characterName]];
        [self addChild:jumpspriteSheet];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:[NSString stringWithFormat:@"%@jumpleft.plist", characterName]];
        CCSpriteBatchNode *jumpleftspriteSheet = [CCSpriteBatchNode batchNodeWithFile:[NSString stringWithFormat:@"%@jumpleft.plist", characterName]];
        [self addChild:jumpleftspriteSheet];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:[NSString stringWithFormat:@"%@falling.plist", characterName]];
        CCSpriteBatchNode *fallingpriteSheet = [CCSpriteBatchNode batchNodeWithFile:[NSString stringWithFormat:@"%@falling.plist", characterName]];
        [self addChild:fallingpriteSheet];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:[NSString stringWithFormat:@"%@_getup.plist", characterName]];
        CCSpriteBatchNode *getUpSheet = [CCSpriteBatchNode batchNodeWithFile:[NSString stringWithFormat:@"%@_getup.plist", characterName]];
        [self addChild:getUpSheet];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"yeti_punch.plist"];
        CCSpriteBatchNode *punchSheet = [CCSpriteBatchNode batchNodeWithFile:@"yeti_punch.png"];
        [self addChild:punchSheet];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:[NSString stringWithFormat:@"%@_cage.plist", characterName]];
        CCSpriteBatchNode *cageSheet = [CCSpriteBatchNode batchNodeWithFile:[NSString stringWithFormat:@"%@_cage.png", characterName]];
        [self addChild:cageSheet];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"yeti_running.plist"];
        CCSpriteBatchNode *yetiRunningSheet = [CCSpriteBatchNode batchNodeWithFile:@"yeti_running.png"];
        [self addChild:yetiRunningSheet];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"unicorn_running.plist"];
        CCSpriteBatchNode *unicornRunningSheet = [CCSpriteBatchNode batchNodeWithFile:@"unicorn_running.png"];
        [self addChild:unicornRunningSheet];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"mermaid_running.plist"];
        CCSpriteBatchNode *mermaidRunningSheet = [CCSpriteBatchNode batchNodeWithFile:@"mermaid_running.png"];
        [self addChild:mermaidRunningSheet];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"leprun.plist"];
        CCSpriteBatchNode *leprunSheet = [CCSpriteBatchNode batchNodeWithFile:@"leprun.png"];
        [self addChild:leprunSheet];
        
        //Board Animations
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"yetiboardturn.plist"];
        CCSpriteBatchNode *boardspriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"yetiboardturn.png"];
        [self addChild:boardspriteSheet];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"yetiboardjump.plist"];
        CCSpriteBatchNode *boardjumpspriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"yetiboardjump.png"];
        [self addChild:boardjumpspriteSheet];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"yetiboardjumpleft.plist"];
        CCSpriteBatchNode *boardjumpleftspriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"yetiboardjumpleft.png"];
        [self addChild:boardjumpleftspriteSheet];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"boardbreak.plist"];
        CCSpriteBatchNode *boardBreakSheet = [CCSpriteBatchNode batchNodeWithFile:@"boardbreak.png"];
        [self addChild:boardBreakSheet];
        
        //Hill Object Animations
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"coinspin.plist"];
        CCSpriteBatchNode *coinspriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"coinspin.png"];
        [self addChild:coinspriteSheet];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"coinspins.plist"];
        CCSpriteBatchNode *coinpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"coinspins.png"];
        [self addChild:coinpriteSheet];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"treebreak.plist"];
        CCSpriteBatchNode *treebreakSheet = [CCSpriteBatchNode batchNodeWithFile:@"treebreak.png"];
        [self addChild:treebreakSheet];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"explode.plist"];
        CCSpriteBatchNode *explodeSheet = [CCSpriteBatchNode batchNodeWithFile:@"explode.png"];
        [self addChild:explodeSheet];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"coinExplode.plist"];
        CCSpriteBatchNode *coinExplodeSheet = [CCSpriteBatchNode batchNodeWithFile:@"coinExplode.png"];
        [self addChild:coinExplodeSheet];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"smoke.plist"];
        CCSpriteBatchNode *smokeSheet = [CCSpriteBatchNode batchNodeWithFile:@"smoke.png"];
        [self addChild:smokeSheet];

        //Enemy Animations
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"heli.plist"];
        CCSpriteBatchNode *heliSheet = [CCSpriteBatchNode batchNodeWithFile:@"heli.png"];
        [self addChild:heliSheet];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"ladder.plist"];
        CCSpriteBatchNode *ladderSheet = [CCSpriteBatchNode batchNodeWithFile:@"ladder.png"];
        [self addChild:ladderSheet];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"trapper.plist"];
        CCSpriteBatchNode *trapperSheet = [CCSpriteBatchNode batchNodeWithFile:@"trapper.png"];
        [self addChild:trapperSheet];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"gameovertrapper.plist"];
        CCSpriteBatchNode *gameovertrapperSheet = [CCSpriteBatchNode batchNodeWithFile:@"gameovertrapper.png"];
        [self addChild:gameovertrapperSheet];
        
        //Background Animations
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:[NSString stringWithFormat:@"%@%@", @"excalibur", @"_lighting.plist"]];
        CCSpriteBatchNode *lightingSheet = [CCSpriteBatchNode batchNodeWithFile:[NSString stringWithFormat:@"%@%@", @"excalibur", @"_lighting.png"]];
        [self addChild:lightingSheet];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:[NSString stringWithFormat:@"%@%@", @"mjolnir", @"_lighting.plist"]];
        CCSpriteBatchNode *lightingSheet2 = [CCSpriteBatchNode batchNodeWithFile:[NSString stringWithFormat:@"%@%@", @"mjolnir", @"_lighting.png"]];
        [self addChild:lightingSheet2];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:[NSString stringWithFormat:@"%@%@", @"icarus", @"_lighting.plist"]];
        CCSpriteBatchNode *lightingSheet3 = [CCSpriteBatchNode batchNodeWithFile:[NSString stringWithFormat:@"%@%@", @"icarus" , @"_lighting.png"]];
        [self addChild:lightingSheet3];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:[NSString stringWithFormat:@"%@%@", @"midas", @"_lighting.plist"]];
        CCSpriteBatchNode *lightingSheet4 = [CCSpriteBatchNode batchNodeWithFile:[NSString stringWithFormat:@"%@%@", @"midas" , @"_lighting.png"]];
        [self addChild:lightingSheet4];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"mtnrumble.plist"];
        CCSpriteBatchNode *mtnRumbleSheet = [CCSpriteBatchNode batchNodeWithFile:@"mtnrumble.png"];
        [self addChild:mtnRumbleSheet];
        
        //Power Ups Animations
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"pheonixlighting.plist"];
        CCSpriteBatchNode *pheonixlightingSheet = [CCSpriteBatchNode batchNodeWithFile:@"pheonixlighting.png"];
        [self addChild:pheonixlightingSheet];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"griffinfly.plist"];
        CCSpriteBatchNode *griffinflySheet = [CCSpriteBatchNode batchNodeWithFile:@"griffinfly.png"];
        [self addChild:griffinflySheet];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"pheonixfly.plist"];
        CCSpriteBatchNode *pheonixflySheet = [CCSpriteBatchNode batchNodeWithFile:@"pheonixfly.png"];
        [self addChild:pheonixflySheet];
        
        
        _man = [CCSprite spriteWithFile:[NSString stringWithFormat:@"%@Turning01.png", characterName]];  // 4
        _board = [CCSprite spriteWithFile:@"board_turning01.png"];  
        CGSize winSize = [CCDirector sharedDirector].winSize; // 5
        _man.position = ccp(100, winSize.height - 200); // 6
        begin = YES;
        jumpOrigin = winSize.height - 210;
        dropShadowSprite = [CCSprite spriteWithSpriteFrame:[_man displayedFrame]];
        [dropShadowSprite setOpacity:100];
        [dropShadowSprite setColor:ccBLACK];
        [dropShadowSprite setPosition:ccp(_man.position.x, _man.position.y)];
        [self addChild:dropShadowSprite z:899];
        
        NSString *dummyName1;
        NSString *dummyName2;
        
        if([[[SettingsManager sharedSettingsManager] getString:@"character"] isEqualToString:@"yeti"]){
            dummyName1 = @"unicorn";
            dummyName2 = @"mermaid";
        }else if([[[SettingsManager sharedSettingsManager] getString:@"character"] isEqualToString:@"unicorn"]){
            dummyName1 = @"yeti";
            dummyName2 = @"mermaid";
        }else if([[[SettingsManager sharedSettingsManager] getString:@"character"] isEqualToString:@"mermaid"]){
            dummyName1 = @"unicorn";
            dummyName2 = @"yeti";
        }
        
        dummy1 = [CCSprite spriteWithFile:[NSString stringWithFormat:@"%@Turning01.png", dummyName1]];  // 4
        dummy2 = [CCSprite spriteWithFile:[NSString stringWithFormat:@"%@Turning01.png", dummyName2]];
        dummy3 = [CCSprite spriteWithFile:@"leprachanRunning1.png"];
        dummy1.position = ccp(100, winSize.height - 190);
        dummy2.position = ccp(100, winSize.height - 190);
        dummy3.position = ccp(100, winSize.height - 190);
        
        [self addChild:dummy1 z:900];
        [self addChild:dummy2 z:900];
        [self addChild:dummy3 z:899];
        
        NSMutableArray *lepRunArray = [NSMutableArray array];
        for(int i = 1; i <= 2; ++i) {
            [lepRunArray addObject:
             [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
              [NSString stringWithFormat:@"leprachanRunning%d.png", i]]];
        }
        
        CCAnimation *lepRunAn = [CCAnimation animationWithFrames:lepRunArray delay:0.2f];
        [dummy3 runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:lepRunAn restoreOriginalFrame:NO]]];
        
        NSMutableArray *yetiRunArray = [NSMutableArray array];
        for(int i = 1; i <= 2; ++i) {
            [yetiRunArray addObject:
             [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
              [NSString stringWithFormat:@"%@Running%d.png", dummyName1, i]]];
        }
        
        CCAnimation *yetiRun = [CCAnimation animationWithFrames:yetiRunArray delay:0.2f];
        [dummy2 runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:yetiRun restoreOriginalFrame:NO]]];
        
        NSMutableArray *uniRunArray = [NSMutableArray array];
        for(int i = 1; i <= 2; ++i) {
            [uniRunArray addObject:
             [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
              [NSString stringWithFormat:@"%@Running%d.png", dummyName2, i]]];
        }
        
        CCAnimation *uniRun = [CCAnimation animationWithFrames:uniRunArray delay:0.2f];
        [dummy1 runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:uniRun restoreOriginalFrame:NO]]];
        
        dropShadowBoardSprite = [CCSprite spriteWithSpriteFrame:[_board displayedFrame]];
        [dropShadowBoardSprite setOpacity:100];
        [dropShadowBoardSprite setColor:ccBLACK];
        [dropShadowBoardSprite setPosition:ccp(_board.position.x, _board.position.y)];
        [self addChild:dropShadowBoardSprite z:899];
        [self addChild:_man z:900];
        _board.position = ccp(100, winSize.height - 190);
        [self addChild:_board z:899];
        
        cabin = [CCSprite spriteWithFile:@"cabin.png"];
        cabin.position = ccp(0 + cabin.boundingBox.size.width/2, winSize.height - 130);
        [self addChild:cabin z:900];
        
        smoke = [CCSprite spriteWithFile:@"smoke1.png"];
        smoke.position = ccp(78, winSize.height - 70);
        [self addChild:smoke z:899];
        
        NSMutableArray *smokeArray = [NSMutableArray array];
        for(int i = 1; i <= 3; ++i) {
            [smokeArray addObject:
             [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
              [NSString stringWithFormat:@"smoke%d.png", i]]];
        }
        
        CCAnimation *smokeAn = [CCAnimation animationWithFrames:smokeArray delay:0.2f];
        [smoke runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:smokeAn restoreOriginalFrame:NO]]];
        
        if(![equipmentName isEqualToString:@"none"]){
            equipment = [CCSprite spriteWithFile:[NSString stringWithFormat:@"%@%@", equipmentName, @".png"]];
            equipment.position = ccp(_man.position.x + [[[equipmentDic objectForKey:equipmentName] objectForKey:@"x"] intValue], _man.position.y + [[[equipmentDic objectForKey:equipmentName] objectForKey:@"y"] intValue]);
            equipment.anchorPoint = ccp(([(NSNumber *)[[equipmentDic objectForKey:equipmentName] objectForKey:@"anchorX"] floatValue]), ([(NSNumber *)[[equipmentDic objectForKey:equipmentName] objectForKey:@"anchorY"] floatValue]));
            equipment.scale = 0;
            equipment.opacity = 0;
        }else{
            equipment = [CCSprite spriteWithFile:@"excalibur.png"];
            equipment.position = ccp(_man.position.x + [[[equipmentDic objectForKey:@"excalibur"] objectForKey:@"x"] intValue], _man.position.y + [[[equipmentDic objectForKey:@"excalibur"] objectForKey:@"y"] intValue]);
            equipment.visible = NO;
        }
        
        [self addChild:equipment z:900];
        
        cloud1 = [CCSprite spriteWithFile:@"cloud1.png"];
        cloud1.position = ccp(-50, winSize.height - 45);
        cloud2 = [CCSprite spriteWithFile:@"cloud1.png"];
        cloud2.position = ccp(winSize.width+50, winSize.height - 110);
        cloud3 = [CCSprite spriteWithFile:@"cloud2.png"];
        cloud3.position = ccp(-50, winSize.height - 75);
        
        [self addChild:cloud1 z:899];
        [self addChild:cloud2 z:899];
        [self addChild:cloud3 z:899];
        
        streak = [CCMotionStreak streakWithFade:0.5 minSeg:0.1 image:@"snowflake.png" width:.1 length:.1 color:ccc4(255, 255, 255, 255)];
        streak.position=ccp(_man.position.x, _man.position.y-20);
        [self addChild:streak z:900];
        
        heli = [CCSprite spriteWithFile:@"heli1.png"];
        heli.position = ccp(winSize.width/2, winSize.height + 140);
        [self addChild:heli z:902];
        NSMutableArray *heliArray = [NSMutableArray array];
        for(int i = 1; i <= 2; ++i) {
            [heliArray addObject:
             [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
              [NSString stringWithFormat:@"heli%d.png", i]]];
        }
        
        CCAnimation *helispin = [CCAnimation animationWithFrames:heliArray delay:0.2f];
        [heli runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:helispin restoreOriginalFrame:NO]]];
        
        ladder = [CCSprite spriteWithFile:@"ladder1.png"];
        ladder.position = ccp(winSize.width/2 + 40, winSize.height + 95);
        [self addChild:ladder z:902];
        NSMutableArray *ladderArray = [NSMutableArray array];
        for(int i = 1; i <= 4; ++i) {
            [ladderArray addObject:
             [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
              [NSString stringWithFormat:@"ladder%d.png", i]]];
        }
        
        CCAnimation *laddershake = [CCAnimation animationWithFrames:ladderArray delay:0.2f];
        [ladder runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:laddershake restoreOriginalFrame:NO]]];
        
        trapper = [CCSprite spriteWithFile:@"trapper_heli1.png"];
        trapper.position = ccp(winSize.width/2 + 30, winSize.height + 38);
        [self addChild:trapper z:902];
        NSMutableArray *trapperArray = [NSMutableArray array];
        for(int i = 1; i <= 2; ++i) {
            [trapperArray addObject:
             [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
              [NSString stringWithFormat:@"trapper_heli%d.png", i]]];
        }
        
        CCAnimation *trappershake = [CCAnimation animationWithFrames:trapperArray delay:0.2f];
        [trapper runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:trappershake restoreOriginalFrame:NO]]];
        
        // 1) Create the CCParallaxNode
        _backgroundNode = [CCParallaxNode node];
        [self addChild:_backgroundNode z:-1];
        
        // 2) Create the sprites we'll add to the CCParallaxNode
        _background1 = [CCSprite spriteWithFile:@"hill1.png"];
        _background2 = [CCSprite spriteWithFile:@"whitebg.png"];
        
        bg = [CCSprite spriteWithFile:@"hill1.png"];
        bg.anchorPoint = ccp(0.5f,1.0f);
        [bg setPosition:ccp(winSize.width/2, winSize.height-161)];
        
        CCSprite *top = [CCSprite spriteWithFile:@"sky_bg.png"];
        [top setPosition:ccp(winSize.width/2, winSize.height - top.contentSize.height/2)];
        
        mtnTop = [CCSprite spriteWithFile:@"mountainAnimation_1.png"];
        [mtnTop setPosition:ccp(winSize.width/2, winSize.height - top.contentSize.height/2)];
        
        [self addChild:top z:480];
        [self addChild:mtnTop z:481];
        [self addChild:bg z:500];
        
        if(![equipmentName isEqualToString:@"none"]){
            lighting = [CCSprite spriteWithFile:[NSString stringWithFormat:@"%@%@", equipmentName, @"_bg_animation6.png"]];
        }else{
            lighting = [CCSprite spriteWithFile:[NSString stringWithFormat:@"%@%@", @"excalibur", @"_bg_animation6.png"]];
        }
        
        [lighting setPosition:ccp(winSize.width/2, winSize.height - lighting.contentSize.height/2)];
        [self addChild:lighting z:479];
        
        if(![equipmentName isEqualToString:@"none"]){
             equipmentText = [CCSprite spriteWithFile:[NSString stringWithFormat:@"%@%@", equipmentName, @"_text.png"]];
        }else{
             equipmentText = [CCSprite spriteWithFile:[NSString stringWithFormat:@"%@%@", @"excalibur", @"_text.png"]];
        }
       
        [equipmentText setPosition:ccp(winSize.width/2, winSize.height - equipmentText.contentSize.height/2 - 30)];
        [self addChild:equipmentText z:600];
        equipmentText.scale = 0;
        
        // 3) Determine relative movement speeds for space dust and background
        CGPoint dustSpeed = ccp(0, 0.3);
        
        // 4) Add children to CCParallaxNode
        [_backgroundNode addChild:_background1 z:0 parallaxRatio:dustSpeed positionOffset:ccp(winSize.width/2,0)];
        [_backgroundNode addChild:_background2 z:0 parallaxRatio:dustSpeed positionOffset:ccp(winSize.width/2,-(_background1.contentSize.height))];
        
        CCParticleSystemQuad *snowEffect = [CCParticleSystemQuad particleWithFile:@"snow1.plist"];
        
        //[self addChild:snowEffect z:995];
        
        self.isAccelerometerEnabled = YES;
        
        _trees = [[CCArray alloc] initWithCapacity:kNumTrees];
        for(int i = 0; i < kNumTrees; ++i) {
            CCSprite *tree;
            /*if(i%2==0){
                tree = [CCSprite spriteWithFile:@"tree.png"];
            }else{
                tree = [CCSprite spriteWithFile:@"treeArch.png"];
            }*/
            tree = [CCSprite spriteWithFile:@"tree_break1.png"];
            tree.visible = NO;
            [self addChild:tree z:490];
            [_trees addObject:tree];
        }
        
        _rocks = [[CCArray alloc] initWithCapacity:kNumRocks];
        for(int i = 0; i < kNumRocks; ++i) {
            CCSprite *rock;
            rock = [CCSprite spriteWithFile:@"rock.png"];
            rock.visible = NO;
            [self addChild:rock z:898];
            [_rocks addObject:rock];
        }
        
        _spikes = [[CCArray alloc] initWithCapacity:kNumSpikes];
        for(int i = 0; i < kNumSpikes; ++i) {
            CCSprite *spike;
            spike = [CCSprite spriteWithFile:@"spikes.png"];
            spike.visible = NO;
            [self addChild:spike z:898];
            [_spikes addObject:spike];
        }
        
        _coins = [[CCArray alloc] initWithCapacity:kNumCoins];
        for(int i = 0; i < kNumCoins; ++i) {
            CCSprite *coin;
            coin = [CCSprite spriteWithFile:@"coin01.png"];
            coin.visible = NO;
            [self addChild:coin z:898];
            [_coins addObject:coin];
        }
        
        _ices = [[CCArray alloc] initWithCapacity:kNumIce];
        for(int i = 0; i < kNumIce; ++i) {
            CCSprite *ice;
            ice = [CCSprite spriteWithFile:@"ice.png"];
            ice.visible = NO;
            [self addChild:ice z:898];
            [_ices addObject:ice];
        }
        
        _arches = [[CCArray alloc] initWithCapacity:kNumArches];
        for(int i = 0; i < kNumArches; ++i) {
            CCSprite *arch;
            arch = [CCSprite spriteWithFile:@"treeArch.png"];
            arch.visible = NO;
            [self addChild:arch z:898];
            [_arches addObject:arch];
        }
        
        cliff = [CCSprite spriteWithFile:@"jump.png"];
        cliff.visible = NO;
        [self addChild:cliff z:898];
        
        _lives = 4;
        double curTime = CACurrentMediaTime();
        _backgroundSpeed = 3000;
        _randDuration = 2.3;
        
        if([characterName isEqualToString:@"yeti"])
            trail = [ARCH_OPTIMAL_PARTICLE_SYSTEM particleWithFile:@"trail4.plist"];
        if([characterName isEqualToString:@"unicorn"])
            trail = [ARCH_OPTIMAL_PARTICLE_SYSTEM particleWithFile:@"trail6.plist"];
        if([characterName isEqualToString:@"mermaid"])
            trail = [ARCH_OPTIMAL_PARTICLE_SYSTEM particleWithFile:@"trail7.plist"];
        trail.positionType=kCCPositionTypeFree;
		trail.position=ccp(_man.position.x, _man.position.y-10);
        
        jumpHeight = 0;
        jumping = NO;
        
        score = 0;
        scoreTime = 0;
        coinScore = 0;
        
        CCSprite *scoreDistanceLabel = [CCSprite spriteWithFile:@"yd.png"];
        scoreDistanceLabel.position = ccp(winSize.width-25, 23);
        [self addChild:scoreDistanceLabel z:998];
        
        scoreLabel = [CCLabelBMFont labelWithString:[NSString stringWithFormat:@"%d", 0] fntFile:@"distance_24pt.fnt"];
        scoreLabel.anchorPoint = ccp(1.0f,0.5f);
        scoreLabel.position = ccp(winSize.width-45, 25);
        
        [self addChild:scoreLabel z:998];
        
        startButton = [CCMenuItemSprite itemFromNormalSprite:[CCSprite spriteWithFile:@"pauseUI.png"] selectedSprite:[CCSprite spriteWithFile:@"pauseUI.png"] target:self selector:@selector(pause:)];
        //pauseMenu = [CCMenu menuWithItems:startButton, nil];
        startButton.position = ccp(50, 30);
        [self addChild:startButton z:998];
        
        CCSprite *coinUI = [CCSprite spriteWithFile:@"coinUI.png"];
        coinUI.position = ccp(winSize.width - 20, winSize.height - 30);
        [self addChild:coinUI z:998];
        
        coinScoreLabel = [CCLabelBMFont labelWithString:[NSString stringWithFormat:@"%d", 0] fntFile:@"coin_24pt.fnt"];
        coinScoreLabel.anchorPoint = ccp(1.0f,0.5f);
        coinScoreLabel.position = ccp(winSize.width - 35, winSize.height - 33);
        
        [self addChild:coinScoreLabel z:998];
        
        getUpMessage = [CCLabelBMFont labelWithString:@"TAP! TAP! TAP!" fntFile:@"prompts_uni32.fnt" width:100 alignment:UITextAlignmentCenter];
        getUpMessage.position = ccp(winSize.width/2, winSize.height - 410);
        getUpMessage.anchorPoint = ccp(0.5f,0.5f);
        getUpMessage.scale = 0;
        [self addChild:getUpMessage z:998];
        
        startMessage = [CCLabelBMFont labelWithString:@"Tap to start" fntFile:@"prompts_uni32.fnt" width:300 alignment:UITextAlignmentCenter];
        startMessage.position = ccp(winSize.width/2, winSize.height - 380);
        startMessage.anchorPoint = ccp(0.5f,0.5f);
        [self addChild:startMessage z:995];
        
        jumpMessage = [CCLabelBMFont labelWithString:@"Swipe up to jump" fntFile:@"prompts_uni32.fnt" width:350 alignment:UITextAlignmentCenter];
        jumpMessage.anchorPoint = ccp(0.5f,0.5f);
        jumpMessage.visible = NO;
        [self addChild:jumpMessage z:999];
        
        _previousPointsPerSec = 0;
        
        singleTap = [CCGestureRecognizer CCRecognizerWithRecognizerTargetAction:[[[UITapGestureRecognizer alloc]init] autorelease] target:self action:@selector(equipTap:)];
        [self addGestureRecognizer:singleTap];
        
        [self schedule:@selector(moveClouds) interval:.01];
        
        if([[[SettingsManager sharedSettingsManager] getString:@"powerup"] isEqualToString:@"griffin"]){
            griffinB = YES;
            jumping = YES;
            ySpeed = 6;
            griffin = [CCSprite spriteWithFile:@"griffin1.png"];
            griffin.position = ccp(winSize.width/2, winSize.height + 200);
            griffin.scale = 4;
            [self addChild:griffin z:998];
            NSMutableArray *griffinArray = [NSMutableArray array];
            for(int i = 1; i <= 4; ++i) {
                [griffinArray addObject:
                [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
                [NSString stringWithFormat:@"griffin%d.png", i]]];
            }
        
            CCAnimation *griffinFly = [CCAnimation animationWithFrames:griffinArray delay:0.08f];
            [griffin runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:griffinFly restoreOriginalFrame:NO]]];
            [griffin runAction:[CCScaleTo actionWithDuration:4 scale:2]];
            [[SettingsManager sharedSettingsManager] setStringValue:@"none" name:@"powerup"];
            [[SettingsManager sharedSettingsManager] save];
        }else if([[[SettingsManager sharedSettingsManager] getString:@"powerup"] isEqualToString:@"pheonix"]){
            pheonix = [CCSprite spriteWithFile:@"pheonix1.png"];
            pheonixB = YES;
            //pheonix.position = ccp(winSize.width/2, winSize.height + 200);
            //[self addChild:pheonix z:998];
            NSMutableArray *pheonixArray = [NSMutableArray array];
            for(int i = 1; i <= 4; ++i) {
                [pheonixArray addObject:
                 [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
                  [NSString stringWithFormat:@"pheonix%d.png", i]]];
            }
            
            CCAnimation *pheonixFly = [CCAnimation animationWithFrames:pheonixArray delay:0.08f];
            [pheonix runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:pheonixFly restoreOriginalFrame:NO]]];
            [[SettingsManager sharedSettingsManager] setStringValue:@"none" name:@"powerup"];
            [[SettingsManager sharedSettingsManager] save];
            
        }
        if([[[SettingsManager sharedSettingsManager] getString:@"audio"] isEqualToString:@"on"]){
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"gameplay_audio.mp3" loop:YES];
            [SimpleAudioEngine sharedEngine].backgroundMusicVolume = .5;}
    }
    return self;
}

- (void) pause: (id) sender
{
    if(paused){
        paused = NO;
        //[self removeChild:pauseLayer cleanup:YES];
        singleTap = [CCGestureRecognizer CCRecognizerWithRecognizerTargetAction:[[[UITapGestureRecognizer alloc]init] autorelease] target:self action:@selector(equipTap:)];
        [self addGestureRecognizer:singleTap];
        horzRecognizer = [CCGestureRecognizer CCRecognizerWithRecognizerTargetAction:[[[UISwipeGestureRecognizer alloc]init] autorelease] target:self action:@selector(swipeJump)];
        ((UISwipeGestureRecognizer*)horzRecognizer.gestureRecognizer).direction = UISwipeGestureRecognizerDirectionLeft || UISwipeGestureRecognizerDirectionRight;
        [self addGestureRecognizer:horzRecognizer];
        //[[CCDirector sharedDirector] resume];
        [self schedule:@selector(updateTimer) interval:.3];
        NSMutableArray *mtnR = [NSMutableArray array];
        for(int i = 1; i <= 9; ++i) {
            [mtnR addObject:
             [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
              [NSString stringWithFormat:@"mountainAnimation_%d.png", i]]];
        }
        
        mtnRum = [CCAnimation animationWithFrames:mtnR delay:0.1f];
        [mtnTop runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:mtnRum restoreOriginalFrame:NO]]];
        
    }else{
        paused = YES;
        //[[CCDirector sharedDirector] pause];
        [self removeGestureRecognizer:singleTap];
        [self removeGestureRecognizer:horzRecognizer];
        pauseLayer = [[PauseLayer alloc] init];
        [self addChild:pauseLayer z:998];
        [self unschedule:@selector(updateTimer)];
        [self unschedule:@selector(playChop)];
        [mtnTop stopAllActions];
    }
}

- (float)randomValueBetween:(float)low andValue:(float)high {
    return (((float) arc4random() / 0xFFFFFFFFu) * (high - low)) + low;
}

- (void)update:(ccTime)dt {
    if(!paused){
    CGPoint backgroundScrollVel = ccp(0, _backgroundSpeed);
    CGPoint asteroidScrollVel = ccp(0, _backgroundSpeed/3.4);
    CGPoint asteroidScrollVelDown = ccp(0, _backgroundSpeed/12);
    CGPoint asteroidScrollCabin = ccp(0, _backgroundSpeed/8);
    
    _backgroundNode.position = ccpAdd(_backgroundNode.position, ccpMult(backgroundScrollVel, dt));
    
    NSArray *spaceDusts = [NSArray arrayWithObjects:_background1, _background2, nil];
    for (CCSprite *spaceDust in spaceDusts) {
        if ([_backgroundNode convertToWorldSpace:spaceDust.position].y > spaceDust.contentSize.height) {
            [_backgroundNode incrementOffset:ccp(0,-(2*spaceDust.contentSize.height)) forChild:spaceDust];
        }
    }
    CGSize winSize = [CCDirector sharedDirector].winSize;
    float maxX = winSize.width - _man.contentSize.width/2;
    float minX = _man.contentSize.width/2;
    
    if(!fallen){
    
        if(heli.position.y <= winSize.height + 140){
            heli.position = ccp(heli.position.x, heli.position.y + .5);
            ladder.position = ccp(ladder.position.x, ladder.position.y + .5);
            trapper.position = ccp(trapper.position.x, trapper.position.y + .5);
            [self schedule:@selector(playChop) interval:.2];
        }else{
            [self unschedule:@selector(playChop)];
        }
    
    float newX = _man.position.x + (_shipPointsPerSecY * dt);
    newX = MIN(MAX(newX, minX), maxX);
        
    if(!jumping){
        if(_man.position.y < jumpOrigin + 32 && _man.position.y > jumpOrigin + 25){
            ySpeed += 0.2f;
            _man.position = ccp(newX, _man.position.y - ySpeed);
            _board.position = ccp(newX, _board.position.y - ySpeed);
            [trail resetSystem];
        }else if(_man.position.y > jumpOrigin){
            ySpeed += 0.2f;
            _man.scale = 1.04;
            _man.position = ccp(newX, _man.position.y - ySpeed);
            _board.position = ccp(newX, _board.position.y - ySpeed);
            
        }else if(_man.position.y < jumpOrigin){
            _man.position = ccp(newX, jumpOrigin);
            _board.position = ccp(newX, jumpOrigin);
        }else{
            tricker = NO;
            _man.scale = 1;
            _man.position = ccp(newX, _man.position.y);
            _board.position = ccp(newX, _board.position.y); 
        }
    }else if(griffinB && score == 1000){
        griffinB = NO;
        jumping = NO;
        timer = 400;
        [griffin runAction:[CCScaleTo actionWithDuration:2 scale:4]];
        [griffin runAction:[CCMoveTo actionWithDuration:2 position:CGPointMake(-200, winSize.height + 200)]];
    }else if(griffinB && _man.position.y > jumpOrigin+ 100){
        _man.position = ccp(newX, _man.position.y);
        _board.position = ccp(newX, _board.position.y);
        griffin.position = ccp(newX - 10, griffin.position.y);
        scoreFlipper = 4;
    }else if(icarus && _man.position.y > jumpOrigin+ 140){
        _man.position = ccp(newX, _man.position.y);
        _board.position = ccp(newX, _board.position.y);
        jumping = NO;
        icarus = NO;
        equipment.opacity = 50;
        [equipment runAction:[CCScaleTo actionWithDuration:0.5 scale:0.3]];
        if(oneUse){
            equipment.visible = NO;
            oneUse = NO;
        }
    }else if(bigJump && _man.position.y > jumpOrigin + 110){
        jumping = NO;
        bigJump = NO;
        ySpeed = 2;
        timer = timer - 200;
    }else if(bigJump || icarus){
        if(ySpeed > .5)
            ySpeed -= 0.3f;
        _man.scale = 1.09;
        _man.position = ccp(newX, _man.position.y + ySpeed);
        _board.position = ccp(newX, _board.position.y + ySpeed);
    }else if(griffinB){
        if(griffin.position.y == _man.position.y + 92){
            griffin.position = ccp(newX - 10, griffin.position.y + 1);
            _man.position = ccp(newX, _man.position.y + 1);
            _board.position = ccp(newX, _board.position.y + 1);
            [trail stopSystem];
            timer = 2000;
            scoreFlipper = 4;
            if(_man.position.y - 1 == jumpOrigin)
                if([[[SettingsManager sharedSettingsManager] getString:@"sfx"] isEqualToString:@"on"])
                    [[SimpleAudioEngine sharedEngine] playEffect:@"griffin.mp3"];
            [[GameKitHelper sharedGameKitHelper] reportAchievementIdentifier:kAchievementsWinging percentComplete:100.0];
        }else{
            griffin.position = ccp(newX - 10, griffin.position.y - 2);
            _man.position = ccp(newX, jumpOrigin);
            _board.position = ccp(newX, jumpOrigin);
        }
    }else{
        ySpeed -= 0.2f;
        _man.scale = 1.09;
        _man.position = ccp(newX, _man.position.y + ySpeed);
        _board.position = ccp(newX, _board.position.y + ySpeed);
    }
            
    NSString *path=[[NSBundle mainBundle] pathForResource:@"equipment" ofType:@"plist"];
    //Next create the dictionary from the contents of the file.
    equipmentDic = [NSDictionary dictionaryWithContentsOfFile:path];
    
        if(![equipmentName isEqualToString:@"icarus"]){
    if(equipment.position.y < _man.position.y + [[[equipmentDic objectForKey:equipmentName] objectForKey:@"y"] intValue] + 1){
        if(equipment.position.x < _man.position.x + [[[equipmentDic objectForKey:equipmentName] objectForKey:@"x"] intValue]){
            equipment.position = ccp(equipment.position.x + ((_man.position.x + [[[equipmentDic objectForKey:equipmentName] objectForKey:@"x"] intValue])-equipment.position.x)/10, equipment.position.y + ((_man.position.y + [[[equipmentDic objectForKey:equipmentName] objectForKey:@"y"] intValue] + 1)-equipment.position.y)/10);
        }else{
            equipment.position = ccp(equipment.position.x - abs(((_man.position.x + [[[equipmentDic objectForKey:equipmentName] objectForKey:@"x"] intValue])-equipment.position.x)/10), equipment.position.y + ((_man.position.y + [[[equipmentDic objectForKey:equipmentName] objectForKey:@"y"] intValue] + 1)-equipment.position.y)/10);
        }
    }else{
        if(equipment.position.x < _man.position.x + [[[equipmentDic objectForKey:equipmentName] objectForKey:@"x"] intValue]){
            equipment.position = ccp(equipment.position.x + ((_man.position.x + [[[equipmentDic objectForKey:equipmentName] objectForKey:@"x"] intValue])-equipment.position.x)/10, equipment.position.y - abs(((_man.position.y + [[[equipmentDic objectForKey:equipmentName] objectForKey:@"y"] intValue] + 1)-equipment.position.y))/10);
        }else{
            equipment.position = ccp(equipment.position.x - abs(((_man.position.x + [[[equipmentDic objectForKey:equipmentName] objectForKey:@"x"] intValue])-equipment.position.x)/10), equipment.position.y - abs(((_man.position.y + [[[equipmentDic objectForKey:equipmentName] objectForKey:@"y"] intValue] + 1)-equipment.position.y))/10);
        }
    }}else{
        equipment.position = ccp((_man.position.x + [[[equipmentDic objectForKey:equipmentName] objectForKey:@"x"] intValue]), (_man.position.y + [[[equipmentDic objectForKey:equipmentName] objectForKey:@"y"] intValue] + 1));
    }
        
    if(equipment.scale < 1) {
        equipment.scale += 0.001;
        if(scoreFlipper == 4){
            if(equipment.opacity < 50){
                equipment.opacity = 50;
            }else{
                equipment.opacity += 1;
            }
        }
    }else{
        equipment.scale = 1;
        equipment.opacity = 255;
    }
        
    if(cabin.position.y > winSize.height- 70 && cabin.zOrder > 490){
        [self reorderChild:cabin z:490];
        [self reorderChild:smoke z:490];
        cabin.position = ccpSub(cabin.position, ccpMult(asteroidScrollVelDown, dt));
        smoke.position = ccpSub(smoke.position, ccpMult(asteroidScrollVelDown, dt));
    }else if(cabin.zOrder == 490){
        cabin.position = ccpSub(cabin.position, ccpMult(asteroidScrollVelDown, dt));
        smoke.position = ccpSub(smoke.position, ccpMult(asteroidScrollVelDown, dt));
    }else{
        cabin.position = ccpAdd(cabin.position, ccpMult(asteroidScrollVelDown, dt));
        smoke.position = ccpAdd(smoke.position, ccpMult(asteroidScrollVelDown, dt));
    }
        
    /*if(jumpMessage.position.y > winSize.height - 150 && jumpMessage.zOrder > 490){
        [self reorderChild:jumpMessage z:490];
        jumpMessage.position = ccpSub(jumpMessage.position, ccpMult(asteroidScrollVelDown, dt));
    }else if(jumpMessage.zOrder == 490){
        jumpMessage.position = ccpSub(jumpMessage.position, ccpMult(asteroidScrollVelDown, dt));
    }else{
        jumpMessage.position = ccpAdd(jumpMessage.position, ccpMult(asteroidScrollVel, dt));
    }*/

    [self turnBoard];
    
    [dropShadowSprite setDisplayFrame:[_man displayedFrame]];
    dropShadowSprite.position = ccp(newX, jumpOrigin);
    
    [dropShadowBoardSprite setDisplayFrame:[_board displayedFrame]];
    dropShadowBoardSprite.position = ccp(newX, jumpOrigin);
    
    double curTime = CACurrentMediaTime();
    _backgroundSpeed = 840 + timer;

    if (curTime > _nextAsteroidSpawn && !bigJump) {
        CCSprite *newTree = [CCSprite spriteWithFile:@"tree_break1.png"];
        
        float randSecs = [self randomValueBetween:450/_backgroundSpeed andValue:750/_backgroundSpeed];
        _nextAsteroidSpawn = randSecs + curTime;
        
        float randX = [self randomValueBetween:0.0 andValue:winSize.width];
        float randTree = [self randomValueBetween:0.0 andValue:10.0];
        
        CCSprite *asteroid1 = [_trees objectAtIndex:_nextAsteroid];
            _nextAsteroid++;
            
        if (_nextAsteroid >= _trees.count)
                _nextAsteroid = 0;
        
        [asteroid1 stopAllActions];
        asteroid1.position = ccp(randX-20, -150);
        [self reorderChild:asteroid1 z:900];
        [asteroid1 setDisplayFrame:newTree.displayedFrame];
        [asteroid1 setTexture:[[CCSprite spriteWithFile:@"tree_break1.png"]texture]];
        asteroid1.visible = YES;
        
        
        if((int)randTree > 2 && (int)randTree < 4){
        CCSprite *asteroid2 = [_trees objectAtIndex:_nextAsteroid];
        _nextAsteroid++;
        
            if (_nextAsteroid >= _trees.count)
                _nextAsteroid = 0;
            
            [asteroid2 stopAllActions];
            asteroid2.position = ccp(randX + (10 + (randTree/2)), -150);
            [self reorderChild:asteroid2 z:900];
            [asteroid2 setDisplayFrame:newTree.displayedFrame];
            [asteroid2 setTexture:[[CCSprite spriteWithFile:@"tree_break1.png"]texture]];
            asteroid2.visible = YES;
            
        }
        
        if((int)randTree > 7 && randTree < 9){
            CCSprite *asteroid2 = [_trees objectAtIndex:_nextAsteroid];
            _nextAsteroid++;
            
            if (_nextAsteroid >= _trees.count)
                _nextAsteroid = 0;
            
            [asteroid2 stopAllActions];
            asteroid2.position = ccp(randX, -150 + (10 + (randTree/2)));
            [self reorderChild:asteroid2 z:900];
            [asteroid2 setDisplayFrame:newTree.displayedFrame];
            [asteroid2 setTexture:[[CCSprite spriteWithFile:@"tree_break1.png"]texture]];
            asteroid2.visible = YES;
            
        CCSprite *asteroid3 = [_trees objectAtIndex:_nextAsteroid];
        _nextAsteroid++;
        
            if (_nextAsteroid >= _trees.count)
                _nextAsteroid = 0;
        
            [asteroid3 stopAllActions];
            asteroid3.position = ccp(randX + (10 + (randTree/2)), -150);
            [self reorderChild:asteroid3 z:900];
            [asteroid3 setDisplayFrame:newTree.displayedFrame];
            [asteroid3 setTexture:[[CCSprite spriteWithFile:@"tree_break1.png"]texture]];
            asteroid3.visible = YES;
        }
    }
    
    if (curTime > _nextRockSpawn && score > 500 && !bigJump) {
        
        float randSecs = [self randomValueBetween:2200/_backgroundSpeed andValue:3500/_backgroundSpeed];
        _nextRockSpawn = randSecs + curTime;
        
        float randX = [self randomValueBetween:0.0 andValue:winSize.width];
        
        CCSprite *rock = [_rocks objectAtIndex:_nextRock];
        _nextRock++;
        if (_nextRock >= _rocks.count) _nextRock = 0;
        
        [rock stopAllActions];
        rock.position = ccp(randX, -100);
        [self reorderChild:rock z:898];
        rock.visible = YES;
    }
        
    if (curTime > _nextIceSpawn && score > 1000 && !bigJump) {
        
        float randSecs = [self randomValueBetween:4000/_backgroundSpeed andValue:6000/_backgroundSpeed];
        _nextIceSpawn = randSecs + curTime;
            
        float randX = [self randomValueBetween:0.0 andValue:winSize.width];
            
        CCSprite *ice = [_ices objectAtIndex:_nextIce];
        _nextIce++;
        if (_nextIce >= _ices.count) _nextIce = 0;
            
        [ice stopAllActions];
        ice.position = ccp(randX, -100);
        [self reorderChild:ice z:898];
        ice.visible = YES;
    }
    
    if (curTime > _nextSpikeSpawn && score > 1700 && !bigJump) {
        
        float randSecs = [self randomValueBetween:3000/_backgroundSpeed andValue:5000/_backgroundSpeed];
        _nextSpikeSpawn = randSecs + curTime;
        
        float randX = [self randomValueBetween:0.0 andValue:winSize.width];
        
        CCSprite *spike = [_spikes objectAtIndex:_nextSpike];
        _nextSpike++;
        if (_nextSpike >= _spikes.count) _nextSpike = 0;
        
        [spike stopAllActions];
        spike.position = ccp(randX, -100);
        [self reorderChild:spike z:898];
        spike.visible = YES;
    }
        
    if (curTime > _nextArchSpawn && score > 100 && !bigJump) {
            
        float randSecs = [self randomValueBetween:5000/_backgroundSpeed andValue:7000/_backgroundSpeed];
        _nextArchSpawn = randSecs + curTime;
            
        float randX = [self randomValueBetween:0.0 andValue:winSize.width];
            
        CCSprite *arch = [_arches  objectAtIndex:_nextArch];
        _nextArch++;
        if (_nextArch >= _arches.count) _nextArch = 0;
            
        [arch stopAllActions];
        arch.position = ccp(randX, -150);
        [self reorderChild:arch z:900];
        arch.visible = YES;
    }
    
    if (curTime > _nextCoinSpawn && !bigJump && score > 30) {
        
        float randSecs = [self randomValueBetween:100/_backgroundSpeed andValue:500/_backgroundSpeed];
        _nextCoinSpawn = randSecs + curTime;
        
        float randX = [self randomValueBetween:0.0 andValue:winSize.width];
        
        CCSprite *coin = [_coins objectAtIndex:_nextCoin];
        _nextCoin++;
        if (_nextCoin >= _coins.count) _nextCoin = 0;
        
        [coin stopAllActions];
        coin.position = ccp(randX, -100);
        [self reorderChild:coin z:898];
        coin.visible = YES;
        NSMutableArray *coinArray = [NSMutableArray array];
        for(int i = 1; i <= 10; ++i) {
            [coinArray addObject:
             [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
              [NSString stringWithFormat:@"coin%d.png", i]]];
        }
        
        CCAnimation *coinspin = [CCAnimation animationWithFrames:coinArray delay:0.1f];
        [coin runAction:[CCRepeat actionWithAction:[CCAnimate actionWithAnimation:coinspin restoreOriginalFrame:NO] times:2]];
    }
    if(curTime > _nextCoinSpawn && !bigJump && score < 40){
        float randSecs = [self randomValueBetween:100/_backgroundSpeed andValue:300/_backgroundSpeed];
        _nextCoinSpawn = randSecs + curTime;
        
        float randX = [self randomValueBetween:0.0 andValue:winSize.width];
        
        CCSprite *coin = [_coins objectAtIndex:_nextCoin];
        _nextCoin++;
        if (_nextCoin >= _coins.count) _nextCoin = 0;
        
        [coin stopAllActions];
        coin.position = ccp(dummy3.position.x, dummy3.position.y);
        [self reorderChild:coin z:898];
        coin.visible = YES;
        NSMutableArray *coinArray = [NSMutableArray array];
        for(int i = 1; i <= 10; ++i) {
            [coinArray addObject:
             [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
              [NSString stringWithFormat:@"coin%d.png", i]]];
        }
        
        CCAnimation *coinspin = [CCAnimation animationWithFrames:coinArray delay:0.1f];
        [coin runAction:[CCRepeat actionWithAction:[CCAnimate actionWithAnimation:coinspin restoreOriginalFrame:NO] times:2]];
    }
    
    if (curTime > _nextCliffSpawn && !bigJump) {
        
        float randSecs = [self randomValueBetween:5000/_backgroundSpeed andValue:10000/_backgroundSpeed];
        _nextCliffSpawn = randSecs + curTime;
        
        float randX = [self randomValueBetween:0.0 andValue:winSize.width];
        
        [cliff stopAllActions];
        cliff.position = ccp(randX, -100);
        [self reorderChild:cliff z:898];
        cliff.visible = YES;
    }
    
    if(bigJump && hitJump){
        bigCliff = [CCSprite spriteWithFile:@"Big_jump.png"];
        hitJump = NO;
        bigCliff.position = ccp(winSize.width/2, -450);
        [self addChild:bigCliff z:898];
        //bigCliff.scale = 3.5f;
        bigCliff.visible = YES;
        
        float hillEquipRan = [self randomValueBetween:1.0 andValue:4.0];
        switch ((int)hillEquipRan)
        {
            case 1:
                hillEquipment = [CCSprite spriteWithFile:@"mjolnir.png"];
                hillEquipment.userData = @"mjolnir";
                break;
            case 2:
                hillEquipment = [CCSprite spriteWithFile:@"excalibur.png"];
                hillEquipment.userData = @"excalibur";
                break;
            case 3:
                hillEquipment = [CCSprite spriteWithFile:@"icarus.png"];
                hillEquipment.userData = @"icarus";
                break;
        }
        if(firstCliff){
            jumpMessage.position = ccp(winSize.width/2, -850);
            jumpMessage.visible = YES;
            [self reorderChild:jumpMessage z:999];
            firstCliff = NO;
        }
        hillEquipment.position = ccp(winSize.width/2, -350);
        [self addChild:hillEquipment z:899];
    }
    
    CGRect bigCliffRect = CGRectMake(bigCliff.boundingBox.origin.x, bigCliff.boundingBox.origin.y+80, bigCliff.boundingBox.size.width, 1);
    CGRect cliffRect = CGRectMake(cliff.boundingBox.origin.x, cliff.boundingBox.origin.y+40, cliff.boundingBox.size.width, 1);
    CGRect shiprect = CGRectMake(_man.boundingBox.origin.x+_man.boundingBox.size.width/2, _man.boundingBox.origin.y+_man.boundingBox.size.height/2, _man.boundingBox.size.width/4, _man.boundingBox.size.height/8);
    CGRect manrect = CGRectMake(_man.boundingBox.origin.x, _man.boundingBox.origin.y, _man.boundingBox.size.width, _man.boundingBox.size.height);
    CGRect boardrect = CGRectMake(_board.boundingBox.origin.x, _board.boundingBox.origin.y, _board.boundingBox.size.width, _board.boundingBox.size.height);
    CGRect equipRect = CGRectMake(equipment.boundingBox.origin.x, equipment.boundingBox.origin.y, equipment.boundingBox.size.width, equipment.boundingBox.size.height);
    CGRect hillEqupRect = CGRectMake(hillEquipment.boundingBox.origin.x, hillEquipment.boundingBox.origin.y, hillEquipment.boundingBox.size.width, hillEquipment.boundingBox.size.height);
    
    if (CGRectIntersectsRect(shiprect, cliffRect) && _man.position.y == jumpOrigin && cliff.zOrder > 490) {
        if([[[SettingsManager sharedSettingsManager] getString:@"sfx"] isEqualToString:@"on"])
        [[SimpleAudioEngine sharedEngine] playEffect:@"hitjump.wav"];
        if(!jumping && _man.position.y == jumpOrigin){
            //[[SimpleAudioEngine sharedEngine] playEffect:@"bigJump.wav"];
            jumping = YES;
            [self schedule:@selector(jumper) interval:.2];
            [trail stopSystem];
            [self doJump];
            ySpeed = 4;
            timer = timer + 25;
            jumps++;
        }
    }
        
    if (CGRectIntersectsRect(shiprect, hillEqupRect) && _man.position.y == jumpOrigin && hillEquipment.zOrder > 490) {
        if(!jumping && _man.position.y == jumpOrigin){
            [self switchEquipment];
        }
    }
        
    if (CGRectIntersectsRect(shiprect, bigCliffRect) && _man.position.y == jumpOrigin && bigCliff.zOrder > 490) {
        if([[[SettingsManager sharedSettingsManager] getString:@"sfx"] isEqualToString:@"on"])
        [[SimpleAudioEngine sharedEngine] playEffect:@"hitjump.wav"];
        if(!jumping && _man.position.y == jumpOrigin){
            jumping = YES;
            [trail stopSystem];
            [self doJump];
            ySpeed = 8;
            tricker = YES;
        }
    }
        
    if (CGRectIntersectsRect(shiprect, bigCliffRect) && icarus){
        [[GameKitHelper sharedGameKitHelper] reportAchievementIdentifier:kAchievementsHangtime percentComplete:100.0];
    }
    
    if(cliff.position.y > winSize.height-160 && cliff.zOrder > 490){
        [self reorderChild:cliff z:490];
        cliff.position = ccpSub(cliff.position, ccpMult(asteroidScrollVelDown, dt));
    }else if(cliff.zOrder == 490){
        cliff.position = ccpSub(cliff.position, ccpMult(asteroidScrollVelDown, dt));
    }else{
        cliff.position = ccpAdd(cliff.position, ccpMult(asteroidScrollVel, dt));
    }
        
    if(bigCliff.position.y > winSize.height-160 && bigCliff.zOrder > 490){
        [self reorderChild:bigCliff z:490];
        if(!tricker)
            bigJump = NO;
        bigCliff.position = ccpSub(bigCliff.position, ccpMult(asteroidScrollVelDown, dt));
    }else if(bigCliff.zOrder == 490){
        bigCliff.position = ccpSub(bigCliff.position, ccpMult(asteroidScrollVelDown, dt));
    }else{
        bigCliff.position = ccpAdd(bigCliff.position, ccpMult(asteroidScrollVel, dt));
    }
        
        if(hillEquipment.position.y > winSize.height - 155 && hillEquipment.zOrder > 490){
            [self reorderChild:hillEquipment z:490];
            hillEquipment.position = ccpSub(hillEquipment.position, ccpMult(asteroidScrollVelDown, dt));
        }else if(hillEquipment.zOrder == 490){
            hillEquipment.position = ccpSub(hillEquipment.position, ccpMult(asteroidScrollVelDown, dt));
        }else{
            hillEquipment.position = ccpAdd(hillEquipment.position, ccpMult(asteroidScrollVel, dt));
        }
    
    for (CCSprite *coin in _coins) {
        if (!coin.visible) continue;
        if(coin.position.y > winSize.height-155 && coin.zOrder > 490){
            [self reorderChild:coin z:490];
            coin.position = ccpSub(coin.position, ccpMult(asteroidScrollVelDown, dt));
        }else if(coin.zOrder == 490){
            coin.position = ccpSub(coin.position, ccpMult(asteroidScrollVelDown, dt));
        }else{
            coin.position = ccpAdd(coin.position, ccpMult(asteroidScrollVel, dt));
        }
        
        CGRect asteroidRect = CGRectMake(coin.boundingBox.origin.x, coin.boundingBox.origin.y, coin.boundingBox.size.width, coin.boundingBox.size.height);
        
        if (CGRectIntersectsRect(manrect, asteroidRect) && !hitTime && coin.zOrder > 700 && _man.position.y < jumpOrigin + 30) {
            if([[[SettingsManager sharedSettingsManager] getString:@"sfx"] isEqualToString:@"on"])
            [[SimpleAudioEngine sharedEngine] playEffect:@"coin.wav"];
            NSMutableArray *coinArray = [NSMutableArray array];
            for(int i = 1; i <= 5; ++i) {
                [coinArray addObject:
                 [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
                  [NSString stringWithFormat:@"coins%d.png", i]]];
            }
            
            CCAnimation *coinspin = [CCAnimation animationWithFrames:coinArray delay:0.02f];
            [coin stopAllActions];
            [coin runAction:[CCAnimate actionWithAnimation:coinspin restoreOriginalFrame:NO]];
            
            coinScore++;
            NSString *str = [NSString stringWithFormat:@"%i", coinScore];
            [coinScoreLabel setString:str];
            if(coinScore == 100){
                [[GameKitHelper sharedGameKitHelper] reportAchievementIdentifier:kAchievementsCoinOne percentComplete:100.0];
            }else if(coinScore == 250){
                [[GameKitHelper sharedGameKitHelper] reportAchievementIdentifier:kAchievementsCoinTwo percentComplete:100.0];
            }else if(coinScore == 500){
                [[GameKitHelper sharedGameKitHelper] reportAchievementIdentifier:kAchievementsCoinThree percentComplete:100.0];
            }
            [self reorderChild:coin z:700];
        }
        
        if (CGRectIntersectsRect(cliffRect, asteroidRect)  && coin.zOrder > 490 && cliff.zOrder > 490) {
            coin.visible = NO;
        }
    }
    
    for (CCSprite *tree in _trees) {
        if (!tree.visible) continue;
        if(tree.position.y > winSize.height-120 && tree.zOrder > 490){
            [self reorderChild:tree z:490];
            tree.position = ccpSub(tree.position, ccpMult(asteroidScrollVelDown, dt));
        }else if(tree.zOrder == 490){
            tree.position = ccpSub(tree.position, ccpMult(asteroidScrollVelDown, dt));
        }else{
            tree.position = ccpAdd(tree.position, ccpMult(asteroidScrollVel, dt));
        }
        
        CGRect asteroidRect = CGRectMake(tree.boundingBox.origin.x + tree.boundingBox.size.width - 20, tree.boundingBox.origin.y, 5, 20);
        
        if (CGRectIntersectsRect(shiprect, asteroidRect) && !hitTime && tree.zOrder > 700 && tree.texture == [[CCSprite spriteWithFile:@"tree_break1.png"]texture] && !griffinB) {
            if([[[SettingsManager sharedSettingsManager] getString:@"sfx"] isEqualToString:@"on"])
            [[SimpleAudioEngine sharedEngine] playEffect:@"hit.wav"];
            [self schedule:@selector(hitTime) interval:1];
            hitTime = YES;
            [_board stopAllActions];
            [_man stopAllActions];
            [_man runAction:[CCMoveTo actionWithDuration:0.4 position:ccp(_man.position.x, _man.position.y-40)]];
            NSMutableArray *fallingArray = [NSMutableArray array];
            for(int i = 1; i <= 3; ++i) {
                [fallingArray addObject:
                 [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
                  [NSString stringWithFormat:@"%@falling%d.png", characterName, i]]];
            }
            [self unschedule:@selector(updateBg)];
            CCAnimation *falling = [CCAnimation animationWithFrames:fallingArray delay:0.01f];
            [_man runAction:[CCAnimate actionWithAnimation:falling restoreOriginalFrame:NO]];
            dropShadowSprite.visible = NO;
            dropShadowBoardSprite.visible = NO;
            [trail stopSystem];
            [self unschedule:@selector(updateTimer)];
            [self unschedule:@selector(updateScoreTimer)];
            _lives--;
            fallen = YES;
            ARCH_OPTIMAL_PARTICLE_SYSTEM *fall = [ARCH_OPTIMAL_PARTICLE_SYSTEM particleWithFile:@"fall2.plist"];
            fall.positionType=kCCPositionTypeFree;
            fall.position=ccp(_man.position.x, _man.position.y-20);
            [self addChild:fall z:899];
            [self reorderChild:tree z:700];
            if([[[SettingsManager sharedSettingsManager] getString:@"sfx"] isEqualToString:@"on"])
            [[SimpleAudioEngine sharedEngine] playEffect:@"falling.wav"];
            [getUpMessage runAction:[CCScaleTo actionWithDuration:.5 scale:1]];
            [getUpMessage runAction:[CCRepeatForever actionWithAction:[CCSequence actions:[CCFadeTo actionWithDuration:.3 opacity:100], [CCDelayTime actionWithDuration:.2],[CCFadeTo actionWithDuration:.3 opacity:255], nil]]];
            [mtnTop stopAllActions];
        }
        
        if (CGRectIntersectsRect(cliffRect, asteroidRect) && tree.zOrder > 490 && cliff.zOrder > 490) {
            //tree.visible = NO;
        }
        
        CGRect treeRect = CGRectMake(tree.position.x, tree.position.y, tree.boundingBox.size.width-80, tree.boundingBox.size.height-tree.boundingBox.size.height/2);
        if (CGRectIntersectsRect(equipRect, treeRect) && !hitTime && tree.zOrder > 700 && !equipActionDone) {
            NSMutableArray *treeArray = [NSMutableArray array];
            for(int i = 1; i <= 3; ++i) {
                [treeArray addObject:
                 [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
                  [NSString stringWithFormat:@"tree_break%d.png", i]]];
            }
            
            [self reorderChild:tree z:700];
            CCAnimation *treebreak = [CCAnimation animationWithFrames:treeArray delay:0.1f];
            [tree runAction:[CCAnimate actionWithAnimation:treebreak restoreOriginalFrame:NO]];
            chopper++;
            if(chopper == 5){
                [[GameKitHelper sharedGameKitHelper] reportAchievementIdentifier:kAchievementsSlapChop percentComplete:100.0];
            }else if(chopper == 50){
                [[GameKitHelper sharedGameKitHelper] reportAchievementIdentifier:kAchievementsSlapChop percentComplete:100.0];
            }
        }else if(CGRectIntersectsRect(equipRect, treeRect) && !hitTime && tree.zOrder > 700 && midas){
            coinScore = coinScore + 4;
            NSMutableArray *treeArray = [NSMutableArray array];
            for(int i = 1; i <= 12; ++i) {
                [treeArray addObject:
                 [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
                  [NSString stringWithFormat:@"coinBurstTest_%d.png", i]]];
            }
            
            [self reorderChild:tree z:700];
            CCAnimation *treebreak = [CCAnimation animationWithFrames:treeArray delay:0.06f];
            [tree runAction:[CCAnimate actionWithAnimation:treebreak restoreOriginalFrame:NO]];
        }
    }
    
    for (CCSprite *rock in _rocks) {
        if (!rock.visible) continue;
        CGRect rockRect = CGRectMake(rock.position.x, rock.position.y + 5, 1, 1);
        
        if (CGRectIntersectsRect(boardrect, rockRect) && _man.position.y == jumpOrigin && rock.zOrder>700 && rock.texture == [[CCSprite spriteWithFile:@"rock.png"] texture]) {
            if([[[SettingsManager sharedSettingsManager] getString:@"sfx"] isEqualToString:@"on"])
            [[SimpleAudioEngine sharedEngine] playEffect:@"falling.wav"];
            [_board stopAllActions];
            [_man stopAllActions];
            NSMutableArray *fallingArray = [NSMutableArray array];
            for(int i = 1; i <= 3; ++i) {
                [fallingArray addObject:
                 [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
                  [NSString stringWithFormat:@"%@falling%d.png", characterName, i]]];
            } 
            CCAnimation *falling = [CCAnimation animationWithFrames:fallingArray delay:0.08f];
            [_man runAction:[CCAnimate actionWithAnimation:falling restoreOriginalFrame:NO]];
            [_man runAction:[CCMoveTo actionWithDuration:0.4 position:ccp(_man.position.x, _man.position.y-40)]];
            NSMutableArray *boardArray = [NSMutableArray array];
            for(int i = 1; i <= 3; ++i) {
                [boardArray addObject:
                 [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
                  [NSString stringWithFormat:@"board_breaking%d.png", i]]];
            }
            CCAnimation *breaking = [CCAnimation animationWithFrames:boardArray delay:0.08f];
            [_board runAction:[CCAnimate actionWithAnimation:breaking restoreOriginalFrame:NO]];
            dropShadowSprite.visible = NO;
            dropShadowBoardSprite.visible = NO;
            ARCH_OPTIMAL_PARTICLE_SYSTEM *fall = [ARCH_OPTIMAL_PARTICLE_SYSTEM particleWithFile:@"fall2.plist"];
            fall.positionType=kCCPositionTypeFree;
            fall.position=ccp(_man.position.x, _man.position.y-20);
            [self addChild:fall z:899];
            [self unschedule:@selector(updateBg)];
            [trail stopSystem];
            [self unschedule:@selector(updateScoreTimer)];
            fallen = true;
            dead = TRUE;
            deadSpeed = 1.2;
            [self reorderChild:rock z:700];
            [mtnTop stopAllActions];
        }
        
        for (CCSprite *asteroid in _trees) {
            
            if (!asteroid.visible) continue;
            CGRect asteroidRect = CGRectMake(asteroid.boundingBox.origin.x, asteroid.boundingBox.origin.y, asteroid.boundingBox.size.width, asteroid.boundingBox.size.height);
            
            if (CGRectIntersectsRect(asteroidRect, rockRect) && rock.zOrder > 490 && asteroid.zOrder > 490) {
                asteroid.visible = NO;
            }
        }
        
        for (CCSprite *asteroid in _spikes) {
            
            if (!asteroid.visible) continue;
            CGRect asteroidRect = CGRectMake(asteroid.boundingBox.origin.x, asteroid.boundingBox.origin.y, asteroid.boundingBox.size.width, asteroid.boundingBox.size.height);
            
            if (CGRectIntersectsRect(asteroidRect, rockRect) && rock.zOrder > 490 && asteroid.zOrder > 490) {
                asteroid.visible = NO;
            }
        }
        
        CGRect cliffRecter = CGRectMake(cliff.boundingBox.origin.x, cliff.boundingBox.origin.y, cliff.boundingBox.size.width, cliff.boundingBox.size.height);
        CGRect rockRectCliff = CGRectMake(rock.boundingBox.origin.x, rock.boundingBox.origin.y, rock.boundingBox.size.width, rock.boundingBox.size.height);
        if (CGRectIntersectsRect(cliffRecter, rockRectCliff) && rock.zOrder > 490 && cliff.zOrder > 490) {
            rock.visible = NO;
        }
        
        if (CGRectIntersectsRect(equipRect, rockRectCliff) && !hitTime && rock.zOrder > 700 && !equipActionDone) {
            if([[[SettingsManager sharedSettingsManager] getString:@"sfx"] isEqualToString:@"on"])
            [[SimpleAudioEngine sharedEngine] playEffect:@"explode.wav"];
            NSMutableArray *explodeArray = [NSMutableArray array];
            for(int i = 1; i <= 6; ++i) {
                [explodeArray addObject:
                 [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
                  [NSString stringWithFormat:@"explode%d.png", i]]];
            }
            CCAnimation *rockExplode = [CCAnimation animationWithFrames:explodeArray delay:0.1f];
            [self reorderChild:rock z:700];
            id rockClean = [CCCallBlock actionWithBlock:^{
                rock.visible = NO;
            }];
            id exploder = [CCAnimate actionWithAnimation:rockExplode restoreOriginalFrame:YES];
            CCSequence *lightAction = [CCSequence actions:exploder, rockClean, nil];
            [rock runAction:lightAction];
            if([equipmentName isEqualToString:@"excalibur"])
                [[GameKitHelper sharedGameKitHelper] reportAchievementIdentifier:kAchievementsLegendary percentComplete:100.0];
            
            if([equipmentName isEqualToString:@"mjolnir"])
                hammerbreak++;
                if(hammerbreak == 5)
                    [[GameKitHelper sharedGameKitHelper] reportAchievementIdentifier:kAchievementsBlockbuster percentComplete:100.0];
            
        }else if(CGRectIntersectsRect(equipRect, rockRectCliff) && !hitTime && rock.zOrder > 700 && midas){
            coinScore = coinScore + 4;
            NSMutableArray *treeArray = [NSMutableArray array];
            for(int i = 1; i <= 12; ++i) {
                [treeArray addObject:
                 [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
                  [NSString stringWithFormat:@"coinBurstTest_%d.png", i]]];
            }
            
            [self reorderChild:rock z:700];
            CCAnimation *treebreak = [CCAnimation animationWithFrames:treeArray delay:0.07f];
            [rock runAction:[CCAnimate actionWithAnimation:treebreak restoreOriginalFrame:NO]];
        }
        
        if(rock.position.y > winSize.height-155 && rock.zOrder > 490){
            [self reorderChild:rock z:490];
            rock.position = ccpSub(rock.position, ccpMult(asteroidScrollVelDown, dt));
        }else if(rock.zOrder == 490){
            rock.position = ccpSub(rock.position, ccpMult(asteroidScrollVelDown, dt));
        }else{
            rock.position = ccpAdd(rock.position, ccpMult(asteroidScrollVel, dt));
        }
    }
    
    for (CCSprite *spike in _spikes) {
        if (!spike.visible) continue;
        CGRect spikeRect = CGRectMake(spike.position.x, spike.position.y, 1, 1);
    
        if (CGRectIntersectsRect(boardrect, spikeRect) && _man.position.y == jumpOrigin && spike.zOrder > 700 && spike.texture == [[CCSprite spriteWithFile:@"spikes.png"] texture]) {
            if([[[SettingsManager sharedSettingsManager] getString:@"sfx"] isEqualToString:@"on"])
            [[SimpleAudioEngine sharedEngine] playEffect:@"falling.wav"];
            [_board stopAllActions];
            [_man stopAllActions];
            [_man runAction:[CCMoveTo actionWithDuration:0.4 position:ccp(_man.position.x, _man.position.y-40)]];
            NSMutableArray *fallingArray = [NSMutableArray array];
            for(int i = 1; i <= 3; ++i) {
                [fallingArray addObject:
                 [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
                  [NSString stringWithFormat:@"%@falling%d.png", characterName, i]]];
            }
            [self unschedule:@selector(updateBg)];
            CCAnimation *falling = [CCAnimation animationWithFrames:fallingArray delay:0.08f];
            [_man runAction:[CCAnimate actionWithAnimation:falling restoreOriginalFrame:NO]];
            NSMutableArray *boardArray = [NSMutableArray array];
            for(int i = 1; i <= 3; ++i) {
                [boardArray addObject:
                 [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
                  [NSString stringWithFormat:@"board_breaking%d.png", i]]];
            }
            CCAnimation *breaking = [CCAnimation animationWithFrames:boardArray delay:0.08f];
            [_board runAction:[CCAnimate actionWithAnimation:breaking restoreOriginalFrame:NO]];
            dropShadowSprite.visible = NO;
            dropShadowBoardSprite.visible = NO;
            [trail stopSystem];
            [self unschedule:@selector(updateScoreTimer)];
            ARCH_OPTIMAL_PARTICLE_SYSTEM *fall = [ARCH_OPTIMAL_PARTICLE_SYSTEM particleWithFile:@"fall2.plist"];
            fall.positionType=kCCPositionTypeFree;
            fall.position=ccp(_man.position.x, _man.position.y-20);
            [self addChild:fall z:899];
            fallen = true;
            dead = TRUE;
            deadSpeed = 1.2;
            [self reorderChild:spike z:700];
            [mtnTop stopAllActions];
        }
        
        for (CCSprite *asteroid in _trees) {
            
            if (!asteroid.visible) continue;
            CGRect asteroidRect = CGRectMake(asteroid.boundingBox.origin.x, asteroid.boundingBox.origin.y, asteroid.boundingBox.size.width, asteroid.boundingBox.size.height);
            
            if (CGRectIntersectsRect(asteroidRect, spikeRect) && spike.zOrder > 490 && asteroid.zOrder > 490) {
                spike.visible = NO;
            }
        }
        
        CGRect cliffRecter = CGRectMake(cliff.boundingBox.origin.x, cliff.boundingBox.origin.y, cliff.boundingBox.size.width, cliff.boundingBox.size.height);
        CGRect spikeRectCliff = CGRectMake(spike.boundingBox.origin.x, spike.boundingBox.origin.y, spike.boundingBox.size.width, spike.boundingBox.size.height);
        if (CGRectIntersectsRect(cliffRecter, spikeRectCliff) && spike.zOrder > 490 && cliff.zOrder > 490) {
            spike.visible = NO;
        }
        
        if (CGRectIntersectsRect(equipRect, spikeRectCliff) && !hitTime && spike.zOrder > 700 && !equipActionDone) {
            if([[[SettingsManager sharedSettingsManager] getString:@"sfx"] isEqualToString:@"on"])
            [[SimpleAudioEngine sharedEngine] playEffect:@"explode.wav"];
            NSMutableArray *explodeArray = [NSMutableArray array];
            for(int i = 1; i <= 6; ++i) {
                [explodeArray addObject:
                 [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
                  [NSString stringWithFormat:@"explode%d.png", i]]];
            }
            CCAnimation *rockExplode = [CCAnimation animationWithFrames:explodeArray delay:0.1f];
            [self reorderChild:spike z:700];
            id rockClean = [CCCallBlock actionWithBlock:^{
                spike.visible = NO;
            }];
            id exploder = [CCAnimate actionWithAnimation:rockExplode restoreOriginalFrame:YES];
            CCSequence *lightAction = [CCSequence actions:exploder, rockClean, nil];
            [spike runAction:lightAction]; 
        }else if(CGRectIntersectsRect(equipRect, spikeRectCliff) && !hitTime && spike.zOrder > 700 && midas){
            coinScore = coinScore + 4;
            NSMutableArray *treeArray = [NSMutableArray array];
            for(int i = 1; i <= 12; ++i) {
                [treeArray addObject:
                 [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
                  [NSString stringWithFormat:@"coinBurstTest_%d.png", i]]];
            }
            
            [self reorderChild:spike z:700];
            CCAnimation *treebreak = [CCAnimation animationWithFrames:treeArray delay:0.07f];
            [spike runAction:[CCAnimate actionWithAnimation:treebreak restoreOriginalFrame:NO]];
        }
    
        if(spike.position.y > winSize.height-155 && spike.zOrder > 490){
            [self reorderChild:spike z:490];
            spike.position = ccpSub(spike.position, ccpMult(asteroidScrollVelDown, dt));
        }else if(spike.zOrder == 490){
            spike.position = ccpSub(spike.position, ccpMult(asteroidScrollVelDown, dt));
        }else{
            spike.position = ccpAdd(spike.position, ccpMult(asteroidScrollVel, dt));
        }
    
    }
        
        for (CCSprite *ice in _ices) {
            if (!ice.visible) continue;
            CGRect iceRect = CGRectMake(ice.boundingBox.origin.x+ice.boundingBox.size.width/2, ice.boundingBox.origin.y+ice.boundingBox.size.height/2, 1, 1);
            
            if (CGRectIntersectsRect(boardrect, iceRect) && _man.position.y == jumpOrigin && ice.zOrder > 700) {
                //[[SimpleAudioEngine sharedEngine] playEffect:@"fall.wav"];
                timer = timer + 500;
                [self reorderChild:ice z:700];
                [self schedule:@selector(slowDown) interval:.5];
            }
            
            for (CCSprite *asteroid in _trees) {
                
                if (!asteroid.visible) continue;
                CGRect asteroidRect = CGRectMake(asteroid.boundingBox.origin.x, asteroid.boundingBox.origin.y, asteroid.boundingBox.size.width, asteroid.boundingBox.size.height);
                
                if (CGRectIntersectsRect(asteroidRect, iceRect) && ice.zOrder > 490 && asteroid.zOrder > 490) {
                    ice.visible = NO;
                }
            }
            
            CGRect cliffRecter = CGRectMake(cliff.boundingBox.origin.x, cliff.boundingBox.origin.y, cliff.boundingBox.size.width, cliff.boundingBox.size.height);
            CGRect spikeRectCliff = CGRectMake(ice.boundingBox.origin.x, ice.boundingBox.origin.y, ice.boundingBox.size.width, ice.boundingBox.size.height);
            if (CGRectIntersectsRect(cliffRecter, spikeRectCliff) && ice.zOrder > 490 && cliff.zOrder > 490) {
                ice.visible = NO;
            }
            
            if(ice.position.y > winSize.height-155 && ice.zOrder > 490){
                [self reorderChild:ice z:490];
                ice.position = ccpSub(ice.position, ccpMult(asteroidScrollVelDown, dt));
            }else if(ice.zOrder == 490){
                ice.position = ccpSub(ice.position, ccpMult(asteroidScrollVelDown, dt));
            }else{
                ice.position = ccpAdd(ice.position, ccpMult(asteroidScrollVel, dt));
            }
            
        }
        
        for (CCSprite *arch in _arches) {
            if (!arch.visible) continue;
            if(arch.position.y > winSize.height-120 && arch.zOrder > 490){
                [self reorderChild:arch z:490];
                arch.position = ccpSub(arch.position, ccpMult(asteroidScrollVelDown, dt));
            }else if(arch.zOrder == 490){
                arch.position = ccpSub(arch.position, ccpMult(asteroidScrollVelDown, dt));
            }else{
                arch.position = ccpAdd(arch.position, ccpMult(asteroidScrollVel, dt));
            }
            
            CGRect archLeftRect = CGRectMake(arch.boundingBox.origin.x + 30, arch.boundingBox.origin.y, 5, 30);
            CGRect archRightRect = CGRectMake(arch.boundingBox.origin.x + arch.boundingBox.size.width - 30, arch.boundingBox.origin.y, 5, 30);
            
            if ((CGRectIntersectsRect(shiprect, archLeftRect) || CGRectIntersectsRect(shiprect, archRightRect)) && !hitTime && arch.zOrder > 700) {
                //[self unscheduleUpdate];
                [self schedule:@selector(hitTime) interval:1];
                hitTime = YES;
                [_board stopAllActions];
                [_man stopAllActions];
                [_man runAction:[CCMoveTo actionWithDuration:0.4 position:ccp(_man.position.x, _man.position.y-40)]];
                NSMutableArray *fallingArray = [NSMutableArray array];
                for(int i = 1; i <= 3; ++i) {
                    [fallingArray addObject:
                     [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
                      [NSString stringWithFormat:@"%@falling%d.png", characterName, i]]];
                }
                [self unschedule:@selector(updateBg)];
                [self unschedule:@selector(updateTimer)];
                CCAnimation *falling = [CCAnimation animationWithFrames:fallingArray delay:0.08f];
                [_man runAction:[CCAnimate actionWithAnimation:falling restoreOriginalFrame:NO]];
                dropShadowSprite.visible = NO;
                dropShadowBoardSprite.visible = NO;
                [trail stopSystem];
                [self unschedule:@selector(updateScoreTimer)];
                _lives--;
                fallen = YES;
                [self reorderChild:arch z:700];
                [getUpMessage runAction:[CCScaleTo actionWithDuration:.5 scale:1]];
                [getUpMessage runAction:[CCRepeatForever actionWithAction:[CCSequence actions:[CCFadeTo actionWithDuration:.3 opacity:100], [CCDelayTime actionWithDuration:.2],[CCFadeTo actionWithDuration:.3 opacity:255], nil]]];
                [mtnTop stopAllActions];
            }
            
            CGRect cliffRecter = CGRectMake(cliff.boundingBox.origin.x, cliff.boundingBox.origin.y, cliff.boundingBox.size.width, cliff.boundingBox.size.height);
            CGRect archRecter = CGRectMake(arch.boundingBox.origin.x, arch.boundingBox.origin.y, arch.boundingBox.size.width, arch.boundingBox.size.height);
            if (CGRectIntersectsRect(cliffRecter, archRecter) && arch.zOrder > 490 && cliff.zOrder > 490) {
                arch.visible = NO;
            }
            
            for (CCSprite *tree in _trees) {
                if (!tree.visible) continue;
                CGRect asteroidRect = CGRectMake(tree.boundingBox.origin.x, tree.boundingBox.origin.y, tree.boundingBox.size.width, tree.boundingBox.size.height);
                if (CGRectIntersectsRect(asteroidRect, archRecter) && arch.zOrder > 490 && tree.zOrder > 490) {
                    tree.visible = NO;
                }
            }
            
            for (CCSprite *spike in _spikes) {
                if (!spike.visible) continue;
                CGRect asteroidRect = CGRectMake(spike.boundingBox.origin.x, spike.boundingBox.origin.y, spike.boundingBox.size.width, spike.boundingBox.size.height);
                if (CGRectIntersectsRect(asteroidRect, archRecter) && arch.zOrder > 490 && spike.zOrder > 490) {
                    spike.visible = NO;
                }
            }
            
            for (CCSprite *rock in _rocks) {
                if (!rock.visible) continue;
                CGRect asteroidRect = CGRectMake(rock.boundingBox.origin.x, rock.boundingBox.origin.y, rock.boundingBox.size.width, rock.boundingBox.size.height);
                if (CGRectIntersectsRect(asteroidRect, archRecter) && arch.zOrder > 490 && rock.zOrder > 490) {
                    rock.visible = NO;
                }
            }
            
            for (CCSprite *ice in _ices) {
                if (!ice.visible) continue;
                CGRect asteroidRect = CGRectMake(ice.boundingBox.origin.x, ice.boundingBox.origin.y, ice.boundingBox.size.width, ice.boundingBox.size.height);
                if (CGRectIntersectsRect(asteroidRect, archRecter) && arch.zOrder > 490 && ice.zOrder > 490) {
                    ice.visible = NO;
                }
            }
        }
    
    trail.position=ccp(_man.position.x, _man.position.y-10);
    streak.position=ccp(_man.position.x, _man.position.y-20);
    
    if(scoreFlipper == 4){
        score++;
        scoreFlipper = 0;
    }else{
        scoreFlipper++;
    }
    NSString *str = [NSString stringWithFormat:@"%i", (int)score];
    [scoreLabel setString:str];
    if(score == 1000){
        [[GameKitHelper sharedGameKitHelper] reportAchievementIdentifier:kAchievementsDistanceOne percentComplete:100.0];
    }else if(score == 2500){
        [[GameKitHelper sharedGameKitHelper] reportAchievementIdentifier:kAchievementsDistanceTwo percentComplete:100.0];
    }else if(score == 5000){
        [[GameKitHelper sharedGameKitHelper] reportAchievementIdentifier:kAchievementsDistanceThree percentComplete:100.0];
    }
        
    if(score == 500 && !jumped){
        [[GameKitHelper sharedGameKitHelper] reportAchievementIdentifier:kAchievementsGrounded percentComplete:100.0];
    }
        
    if(jumps == 10 && [characterName isEqualToString:@"unicorn"]){
        [[GameKitHelper sharedGameKitHelper] reportAchievementIdentifier:kAchievementsShowJumper percentComplete:100.0];
    }
        
    if(score == 1500 && [equipmentName isEqualToString:@"excalibur"] && [characterName isEqualToString:@"mermaid"]){
        [[GameKitHelper sharedGameKitHelper] reportAchievementIdentifier:kAchievementsSwordfish percentComplete:100.0]; 
    }
    
    
    if(score == 500 && !griffinB){
        bigJump = YES;
        hitJump = YES;
    }else if(score == 1000  && !griffinB){
        bigJump = YES;
        hitJump = YES;
    }else if(score == 1700){
        bigJump = YES;
        hitJump = YES;
    }else if(score == 2500){
        bigJump = YES;
        hitJump = YES;
    }else if(score == 4000){
        bigJump = YES;
        hitJump = YES;
    }   
        
    }else{
        double speedY = .9;
        double speedX = .6;
        if(dead){
            speedY = 1.5;
            speedX = 1.2;
        }
        if(!caught){
            [self schedule:@selector(playChop) interval:.2];
            CGRect trapperBound = CGRectMake(trapper.position.x, trapper.position.y, trapper.boundingBox.size.width, trapper.boundingBox.size.height);
            CGRect manBound = CGRectMake(_man.position.x, _man.position.y, _man.boundingBox.size.width, _man.boundingBox.size.height);
            
            if(CGRectIntersectsRect(manBound, trapperBound) && trapper.position.y >= _man.position.y - 5 && trapper.position.y <= _man.position.y + 5  && trapper.position.x <= _man.position.x + 30  && trapper.position.x >= _man.position.x + 20){
                if(pheonixB){
                    pheonix.position = ccp(_man.position.x, _man.position.y);
                    //[self addChild:pheonix z:902];
                    NSMutableArray *pheonixLightingArray = [NSMutableArray array];
                    for(int i = 1; i <= 8; ++i) {
                        [pheonixLightingArray addObject:
                         [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
                          [NSString stringWithFormat:@"pheonix_lightning%d.png", i]]];
                    }
                
                    CCAnimation *pheonixLighting = [CCAnimation animationWithFrames:pheonixLightingArray delay:0.07f];
                
                    pheonixAni = [CCSprite spriteWithFile:@"pheonix_lightning1.png"];
                    pheonixAni.anchorPoint = ccp(0.5f, 0.5f);
                    pheonixAni.position = ccp(winSize.width/2, winSize.height/2);
                    [self addChild:pheonixAni z:999];
                    [pheonixAni runAction:[CCSequence actions:[CCAnimate actionWithAnimation:pheonixLighting restoreOriginalFrame:YES], [CCFadeOut actionWithDuration:.2], [CCCallBlock actionWithBlock:^{[self reorderChild:dummy3 z:899];}], nil]];
                    dead = NO;
                    caught = NO;
                    pheonixB = NO;
                    [self getUp];
                    trapper.position = ccp(winSize.width/2 + 30, winSize.height + 38);
                    ladder.position = ccp(winSize.width/2 + 40, winSize.height + 95);
                    heli.position = ccp(winSize.width/2, winSize.height + 140);
                    if([[[SettingsManager sharedSettingsManager] getString:@"sfx"] isEqualToString:@"on"])
                    [[SimpleAudioEngine sharedEngine] playEffect:@"pheonix.mp3"];
                    [[GameKitHelper sharedGameKitHelper] reportAchievementIdentifier:kAchievementsInsurance percentComplete:100.0];
                }else{
                    //[self removeGestureRecognizer:singleTap];
                    //[self removeGestureRecognizer:horzRecognizer];
                    caught = YES;
                    deadSpeed = 1.4;
                }
            }else{
                speedX = (_man.position.x + 25 - trapper.position.x);
                speedY = (_man.position.y - trapper.position.y);
                
                double distance = sqrt(speedX * speedX + speedY * speedY);
                
                speedX = speedX / distance;
                speedY = speedY / distance;
                
                heli.position = ccp(heli.position.x + speedX, heli.position.y + speedY);
                ladder.position = ccp(ladder.position.x + speedX, ladder.position.y + speedY);
                trapper.position = ccp(trapper.position.x + speedX, trapper.position.y + speedY);
            }
        }else{
            if(_man.position.x < -15 && _man.position.y > winSize.height + 5){
                [self unschedule:@selector(updateScoreTimer)];
                [self endScene:kEndReasonLose];
            }else{
                [self unschedule:@selector(playchop)];
                [self schedule:@selector(playChop) interval:.17];
                deadSpeed += .03;
                heli.position = ccp(heli.position.x - deadSpeed, heli.position.y + deadSpeed);
                ladder.position = ccp(ladder.position.x  - deadSpeed, ladder.position.y + deadSpeed);
                trapper.position = ccp(trapper.position.x - deadSpeed, trapper.position.y + deadSpeed);
                _man.position = ccp(_man.position.x - deadSpeed, _man.position.y + deadSpeed);
            }
        }
    }
    }
}

- (void)setInvisible:(CCNode *)node {
    node.visible = NO;
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
    
    #define kFilteringFactor .6
    #define kRestAccelX 0
    #define kRestAccelY 0
    #define kRestAccelZ -0.6
    #define kShipMaxPointsPerSecWidth (winSize.width*7)
    #define kShipMaxPointsPerSecHeight (winSize.height*0.5)
    #define kMaxDiffX 0.1
    #define kMaxDiffZ 0.3
    #define kMaxDiffY 0.9
    
    UIAccelerationValue rollingX, rollingY, rollingZ;
    
    rollingX = (acceleration.x * kFilteringFactor);// + (rollingX * (1.0 - kFilteringFactor));
    rollingY = (acceleration.y * kFilteringFactor);// + (rollingY * (1.0 - kFilteringFactor));
    rollingZ = (acceleration.z * kFilteringFactor);// + (rollingZ * (1.0 - kFilteringFactor));
    
    float accelX = acceleration.x - rollingX;
    float accelY = acceleration.y - rollingY;
    float accelZ = acceleration.z - rollingZ;
    
    CGSize winSize = [CCDirector sharedDirector].winSize;
    
    float accelDiff = accelX;
    float accelFraction = accelDiff / kMaxDiffX;
    float pointsPerSec = kShipMaxPointsPerSecWidth * accelX;
    
    float accelDiff2 = accelZ - kRestAccelZ;
    float accelFraction2 = accelDiff2 / kMaxDiffZ;
    float pointsPerSec2 = kShipMaxPointsPerSecHeight * accelFraction2;
    
    _shipPointsPerSecY = pointsPerSec;
    _shipPointsPerSecZ = pointsPerSec2;
}

- (void)endScene:(EndReason)endReason {
    if (_gameOver) return;
    _gameOver = true;
    
    gameOverLayer = [[GameOverLayer alloc] init:(int)score coins:(int)coinScore];
    
    [self addChild:gameOverLayer z:999];
    
    [self unscheduleUpdate];
    
    [[GameKitHelper sharedGameKitHelper]
     submitScore:(int64_t)score
     category:kHighScoreLeaderboardCategory];
    
    [[GameKitHelper sharedGameKitHelper] submitScore:(int64_t)coinScore category:kCoinscoreLeaderboardCategory];
    
    
    int totalCoins = [[SettingsManager sharedSettingsManager] getInt:@"coins"];
    if(totalCoins != 0){
        totalCoins = totalCoins + coinScore;
    }else{
        totalCoins = coinScore;
    }
    
    [[SettingsManager sharedSettingsManager] setIntValue:totalCoins name:@"coins"];
    
    [self unschedule:@selector(playChop)];
    [self schedule:@selector(removeGes) interval:.5];
}

-(void)equipTap:(UIGestureRecognizer *)gestureRecognizer{
    if(!caught){
    CGSize winSize = [CCDirector sharedDirector].winSize;
    CGPoint tapPoint = [gestureRecognizer locationInView:gestureRecognizer.view];
    tapPoint = [[CCDirector sharedDirector] convertToGL:tapPoint];
    CGRect tapper = CGRectMake(tapPoint.x, tapPoint.y, 1, 1);
    CGRect pauseRect = startButton.boundingBox;
    if(CGRectIntersectsRect(tapper, pauseRect)){
        [self performSelector:@selector(pause:)];
    }else{
    
    if(_started == NO){
        float randAmp = [self randomValueBetween:50 andValue:80];
        float randFreq = [self randomValueBetween:0.01 andValue:0.04];
        [dummy3 runAction:[CCSequence actions:[CCCallBlock actionWithBlock:^{[self reorderChild:dummy3 z:899];}], [MoveSineAction actionWithDuration:3.3 length:450 amplitude:randAmp frequency:randFreq]/*[CCMoveTo actionWithDuration:2 position:ccp(randX, -30)]*/, nil]];
        [dummy1 runAction:[CCSequence actions:[CCDelayTime actionWithDuration:.6],[CCCallBlock actionWithBlock:^{[self reorderChild:dummy1 z:900];}],[CCMoveTo actionWithDuration:1.3 position:ccp(winSize.width + 30, dummy1.position.y - 65)], nil]];
        [dummy2 runAction:[CCSequence actions:[CCDelayTime actionWithDuration:.8],[CCCallBlock actionWithBlock:^{[self reorderChild:dummy2 z:900];}],[CCMoveTo actionWithDuration:1.5 position:ccp(winSize.width + 30, dummy2.position.y - 5)], nil]];
        float randX = [self randomValueBetween:0.0 andValue:winSize.width];
        [self runAction:[CCSequence actions:[CCCallBlock actionWithBlock:^{[self reorderChild:_man z:900];[self reorderChild:_board z:899];}],[CCDelayTime actionWithDuration:5],[CCCallBlock actionWithBlock:^{[self reorderChild:_man z:900];[self reorderChild:_board z:899];}], nil]];
        [self addChild:trail z:899];
        //[trail resetSystem];
        [self scheduleUpdate];
        [self schedule:@selector(updateTimer) interval:.3];
        [self schedule:@selector(updateBg) interval:.1];
        _started = YES;
        //[self schedule:@selector(firstFall) interval:.2];
        [[GameKitHelper sharedGameKitHelper] reportAchievementIdentifier:kAchievementsTrainingWheels percentComplete:100.0];
        [startMessage runAction:[CCScaleTo actionWithDuration:.5 scale:0]];
        NSMutableArray *mtnR = [NSMutableArray array];
        for(int i = 1; i <= 9; ++i) {
            [mtnR addObject:
             [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
              [NSString stringWithFormat:@"mountainAnimation_%d.png", i]]];
        }
        
        mtnRum = [CCAnimation animationWithFrames:mtnR delay:0.1f];
        [mtnTop runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:mtnRum restoreOriginalFrame:NO]]];
    }else{
    
    if(!fallen && !caught && _started && equipActionDone && equipment.scale == 1 && equipment.visible && tapCount == 0 && !icarus && !midas){
        if([equipmentName isEqualToString:@"mjolnir"]){
            if([[[SettingsManager sharedSettingsManager] getString:@"sfx"] isEqualToString:@"on"])
                [[SimpleAudioEngine sharedEngine] playEffect:@"mjolnir.mp3"];
            [equipment runAction:[CCRepeat actionWithAction:[CCRotateBy actionWithDuration:.4 angle:360] times:3]];
            CGPoint point = [gestureRecognizer locationInView:gestureRecognizer.view];
            point = [[CCDirector sharedDirector]convertToGL:point];
            equipAction = TRUE;
            equipActionDone = NO;
            id move = [CCMoveTo actionWithDuration:1 position:point];
            id cleaner;
            if(!oneUse){
                cleaner = [CCCallBlock actionWithBlock:^{
                equipActionDone = YES;
                [equipment runAction:[CCScaleTo actionWithDuration:0.5 scale:0.3]];
            }];
            }else{
                cleaner = [CCCallBlock actionWithBlock:^{
                    equipActionDone = YES;
                    equipment.visible = NO;
                }];
            }
            CCSequence *action = [CCSequence actions:move, cleaner, nil];
            [equipment runAction:action];
            hammertime++;
            if(hammertime == 10){
                [[GameKitHelper sharedGameKitHelper] reportAchievementIdentifier:kAchievementsHammertime percentComplete:100.0];
            }
        }else if([equipmentName isEqualToString:@"excalibur"]){
            if([[[SettingsManager sharedSettingsManager] getString:@"sfx"] isEqualToString:@"on"])
            [[SimpleAudioEngine sharedEngine] playEffect:@"excalibur.mp3"];
            equipActionDone = NO;
            id orbitAction = [CCRotateBy actionWithDuration:1 angle:360];
            id cleaner;
            if(!oneUse){
             cleaner = [CCCallBlock actionWithBlock:^{
                equipActionDone = YES;
                equipment.opacity = 50;
                [equipment runAction:[CCScaleTo actionWithDuration:0.5 scale:0.3]];
            }];
            }else{
                cleaner = [CCCallBlock actionWithBlock:^{
                    equipActionDone = YES;
                    equipment.visible = NO;
                }];
            }
            CCSequence *action = [CCSequence actions:orbitAction, cleaner, nil];
            [equipment runAction:action];
        }else if([equipmentName isEqualToString:@"midas"]){
            if([[[SettingsManager sharedSettingsManager] getString:@"sfx"] isEqualToString:@"on"])
            [[SimpleAudioEngine sharedEngine] playEffect:@"midas.mp3"];
            midas = YES;
            id orbitAction = [CCRotateBy actionWithDuration:1 angle:180];
            id scaleAction = [CCScaleBy actionWithDuration:1 scale:2];
            id delay = [CCDelayTime actionWithDuration:5];
            id cleaner;
            if(!oneUse){
                cleaner = [CCCallBlock actionWithBlock:^{
                    midas = NO;
                    equipment.opacity = 50;
                    [equipment runAction:[CCScaleTo actionWithDuration:0.5 scale:0.3]];
                    [equipment runAction:[CCRotateBy actionWithDuration:1 angle:-180]];
                }];
            }else{
                cleaner = [CCCallBlock actionWithBlock:^{
                    equipActionDone = YES;
                    equipment.visible = NO;
                }];
            }
            CCSequence *action = [CCSequence actions:orbitAction, scaleAction, delay, cleaner, nil];
            [equipment runAction:action];
            [[GameKitHelper sharedGameKitHelper] reportAchievementIdentifier:kAchievementsGoldFinger percentComplete:100.0];
        }else if([equipmentName isEqualToString:@"icarus"]){
            if([[[SettingsManager sharedSettingsManager] getString:@"sfx"] isEqualToString:@"on"])
            [[SimpleAudioEngine sharedEngine] playEffect:@"icarus.mp3"];
            jumping = YES;
            icarus = YES;
            ySpeed = 6;
            [trail stopSystem];
            NSMutableArray *flapArray = [NSMutableArray array];
            for(int i = 1; i <= 4; ++i) {
                [flapArray addObject:
                 [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
                  [NSString stringWithFormat:@"icarus%d.png", i]]];
            }
            CCAnimation *flap = [CCAnimation animationWithFrames:flapArray delay:0.1f];
            [equipment runAction:[CCRepeat actionWithAction:[CCAnimate actionWithAnimation:flap restoreOriginalFrame:YES] times:12]];
            [[GameKitHelper sharedGameKitHelper] reportAchievementIdentifier:kAchievementsItsABird percentComplete:100.0];
            wings++;
            if(wings == 10){
                [[GameKitHelper sharedGameKitHelper] reportAchievementIdentifier:kAchievementsItsAPlane percentComplete:100.0];
            }else if(wings == 20){
                [[GameKitHelper sharedGameKitHelper] reportAchievementIdentifier:kAchievementsItsSuperMan percentComplete:100.0];
            }
        }
        
        NSString *path=[[NSBundle mainBundle] pathForResource:@"equipment" ofType:@"plist"];
        //Next create the dictionary from the contents of the file.
        equipmentDic = [NSDictionary dictionaryWithContentsOfFile:path];
        NSMutableArray *lightingArray = [NSMutableArray array];
        for(int i = 1; i <= [((NSString *)[[equipmentDic objectForKey:equipmentName] objectForKey:@"frames"]) intValue]; ++i) {
            [lightingArray addObject:
            [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
            [NSString stringWithFormat:[NSString stringWithFormat:@"%@%@", equipmentName, @"_bg_animation%d.png"], i]]];
        }
        CCAnimation *light = [CCAnimation animationWithFrames:lightingArray delay:0.1f];
        id lightClean = [CCCallBlock actionWithBlock:^{
            [equipmentText runAction:[CCScaleTo actionWithDuration:0.3 scale:0]];
            [self reorderChild:lighting z:479];
        }];
        id lightShow = [CCAnimate actionWithAnimation:light restoreOriginalFrame:NO];
        [equipmentText runAction:[CCScaleTo actionWithDuration:0.5 scale:1.0]];
        [self reorderChild:lighting z:481];
        CCSequence *lightAction = [CCSequence actions:lightShow, lightClean, nil];
        [lighting runAction:lightAction];
        }
    }
    }
}
}

-(void)ccTouchesBegan:(NSSet*)touches withEvent:(UIEvent*)event{
    if(!jumping && _man.position.y == jumpOrigin && !fallen ){
           
    }
     if(fallen && tapCount < 10 && !caught && !dead && !paused){
            tapCount++;
            NSMutableArray *getupArray = [NSMutableArray array];
            for(int i = 1; i <= 3; ++i) {
                [getupArray addObject:
                 [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
                  [NSString stringWithFormat:@"%@_getup%d.png", characterName, i]]];
            }
            CCAnimation *getup = [CCAnimation animationWithFrames:getupArray delay:0.1f];
            [_man runAction:[CCAnimate actionWithAnimation:getup restoreOriginalFrame:NO]];
        }else if(fallen && tapCount == 10 && !caught){
            [self getUp];
        }
    
}

-(void)swipe{
    if(!jumping && _man.position.y == jumpOrigin && !fallen && ![[CCDirector sharedDirector] isPaused]){
        _man.scale = 1.1;
        if([[[SettingsManager sharedSettingsManager] getString:@"sfx"] isEqualToString:@"on"])
        [[SimpleAudioEngine sharedEngine] playEffect:@"jump.wav"];
        jumping = YES;
        [self schedule:@selector(jumper) interval:.2];
        [trail stopSystem];
        ySpeed = 4;
        [self doJump];
        jumped = YES;
    }
}

-(void)swipeJump{
    if(jumping && _man.position.y > jumpOrigin && !fallen && ![[CCDirector sharedDirector] isPaused] && tricker){
        [_man runAction:[CCRotateBy actionWithDuration:0.55 angle:360]];
        [dropShadowSprite runAction:[CCRotateBy actionWithDuration:0.55 angle:360]];
        
            if([characterName isEqualToString:@"yeti"]){
            [[GameKitHelper sharedGameKitHelper] reportAchievementIdentifier:kAchievementsBigFeat percentComplete:100.0]; 
        }
    }
}

-(void)getUp{
    _man.position = ccp(_man.position.x, _man.position.y+40);
    NSMutableArray *fallingArray = [NSMutableArray array];
    for(int i = 3; i >= 0; --i) {
        [fallingArray addObject:
         [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
          [NSString stringWithFormat:@"%@falling%d.png", characterName, i]]];
    }
    id setSprites = [CCCallBlock actionWithBlock:^{
        NSMutableArray *leftturnArray = [NSMutableArray array];
        for(int i = 1; i <= 9; ++i) {
            [leftturnArray addObject:
             [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
              [NSString stringWithFormat:@"%@%@%d.png", characterName, @"Turning0", i]]];
        }
        
        leftturn = [CCAnimation animationWithFrames:leftturnArray delay:0.05f];
        [_man runAction:[CCAnimate actionWithAnimation:leftturn restoreOriginalFrame:NO]];
        
        NSMutableArray *leftboardturnArray = [NSMutableArray array];
        for(int i = 1; i <= 9; ++i) {
            [leftboardturnArray addObject:
             [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
              [NSString stringWithFormat:@"board_turning0%d.png", i]]];
        }
        
        boardleftturn = [CCAnimation animationWithFrames:leftboardturnArray delay:0.05f];
        [_board runAction:[CCAnimate actionWithAnimation:boardleftturn restoreOriginalFrame:NO]];
    }];
    CCAnimation *falling = [CCAnimation animationWithFrames:fallingArray delay:0.08f];
    id animateFalling = [CCAnimate actionWithAnimation:falling restoreOriginalFrame:NO];
    CCSequence *getUpAction = [CCSequence actions:animateFalling, setSprites, nil];
    [_man runAction:getUpAction];
    [trail resetSystem];
    hitTime = NO;
    fallen = NO;
    caught = NO;
    dead = NO;
    dropShadowSprite.visible = YES;
    dropShadowBoardSprite.visible = YES;
    // [self scheduleUpdate];
    [self schedule:@selector(updateTimer) interval:.3];
    [self schedule:@selector(updateBg) interval:.1];
    //tapCount = 0;
    [self schedule:@selector(tapCountReset) interval:.5];
    [[GameKitHelper sharedGameKitHelper] reportAchievementIdentifier:kAchievementsChumbawumba percentComplete:100.0];
    [getUpMessage runAction:[CCScaleTo actionWithDuration:.5 scale:0]];
    NSMutableArray *mtnR = [NSMutableArray array];
    for(int i = 1; i <= 9; ++i) {
        [mtnR addObject:
         [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
          [NSString stringWithFormat:@"mountainAnimation_%d.png", i]]];
    }
    
    mtnRum = [CCAnimation animationWithFrames:mtnR delay:0.1f];
    [mtnTop runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:mtnRum restoreOriginalFrame:NO]]];
}



-(void)doJump{
    if(_shipPointsPerSecY > 0){
        NSMutableArray *jumpArray = [NSMutableArray array];
        for(int i = 1; i <= 5; ++i) {
            [jumpArray addObject:
             [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
              [NSString stringWithFormat:@"%@Jumping%d.png", characterName, i]]];
        }
        
        leftturn = [CCAnimation animationWithFrames:jumpArray delay:0.1f];
        [_man runAction:[CCAnimate actionWithAnimation:leftturn restoreOriginalFrame:YES]];
        
        NSMutableArray *rightboardturnArray = [NSMutableArray array];
        for(int i = 5; i >= 1; --i) {
            [rightboardturnArray addObject:
             [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
              [NSString stringWithFormat:@"board_jumping%d.png", i]]];
        }
        
        boardrightturn = [CCAnimation animationWithFrames:rightboardturnArray delay:0.1f];
        [_board runAction:[CCAnimate actionWithAnimation:boardrightturn restoreOriginalFrame:YES]];
    }else{
        NSMutableArray *jumpArray = [NSMutableArray array];
        for(int i = 1; i <= 5; ++i) {
            [jumpArray addObject:
             [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
              [NSString stringWithFormat:@"%@Jumpingleft%d.png", characterName, i]]];
        }
        
        leftturn = [CCAnimation animationWithFrames:jumpArray delay:0.1f];
        [_man runAction:[CCAnimate actionWithAnimation:leftturn restoreOriginalFrame:YES]];
        
        NSMutableArray *rightboardturnArray = [NSMutableArray array];
        for(int i = 5; i >= 1; --i) {
            [rightboardturnArray addObject:
             [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
              [NSString stringWithFormat:@"board_jumpingleft%d.png", i]]];
        }
        
        boardrightturn = [CCAnimation animationWithFrames:rightboardturnArray delay:0.1f];
        
        [_board runAction:[CCAnimate actionWithAnimation:boardrightturn restoreOriginalFrame:YES]];
    }
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {

}

-(void)jumper{
    jumping = NO;
    ySpeed = 2;
    [self unschedule:@selector(jumper)];
}

-(void)bigJump{
    bigJump = NO;
    [self unschedule:@selector(bigJump)];
}

-(void)updateTimer{
    if(timer <= 0){
        timer = timer + 70;
    }else if(timer > 0 && timer <= 200){
        timer = timer + 6;
    }else if(timer > 200 && timer <= 500){
        timer = timer + 4;
    }else if(timer > 500 && timer <= 800){
        timer = timer + 2;
    }else if(timer > 800){
        timer = timer + 1;
    }
    
}

-(void)updateBg{
    if(bg.texture == [[CCSprite spriteWithFile:@"hill1.png"]texture]){
        [bg setTexture:[[CCSprite spriteWithFile:@"hill2.png"]texture]];
    }else if(bg.texture == [[CCSprite spriteWithFile:@"hill2.png"]texture]){
        [bg setTexture:[[CCSprite spriteWithFile:@"hill3.png"]texture]];
    }else if(bg.texture == [[CCSprite spriteWithFile:@"hill3.png"]texture]){
        [bg setTexture:[[CCSprite spriteWithFile:@"hill1.png"]texture]];
    }
}

-(void)slowDown{
    timer = timer - 500;
    [self unschedule:@selector(slowDown)];
}

-(void)hitTime{
    hitTime = NO;
    [self unschedule:@selector(hitTime)];
}

-(void)tapCountReset{
    tapCount = 0;
    [self unschedule:@selector(tapCountReset)];
}

-(void)playChop{
    if([[[SettingsManager sharedSettingsManager] getString:@"sfx"] isEqualToString:@"on"])
        [[SimpleAudioEngine sharedEngine] playEffect:@"helicopter_1chop.mp3"];
}

-(void)removeGes{
    [self removeGestureRecognizer:singleTap];
    [self removeGestureRecognizer:horzRecognizer];
    [self unschedule:@selector(removeGes)];
}


-(void)switchEquipment{
    if(![((NSString *)hillEquipment.userData) isEqualToString:equipmentName]){
    CGSize winSize = [CCDirector sharedDirector].winSize;
    [self removeChild:equipment cleanup:YES];
    NSString *path=[[NSBundle mainBundle] pathForResource:@"equipment" ofType:@"plist"];
    NSString *equipOne;
    equipmentDic = [NSDictionary dictionaryWithContentsOfFile:path];
    
    if([((NSString *)hillEquipment.userData) isEqualToString:@"mjolnir"]){
        equipmentName = @"mjolnir";
        equipOne = @"hammer";
        if([[[SettingsManager sharedSettingsManager] getString:@"sfx"] isEqualToString:@"on"])
            [[SimpleAudioEngine sharedEngine] playEffect:@"mjolnir.mp3"];
    }else if([((NSString *)hillEquipment.userData) isEqualToString:@"excalibur"]){
        equipmentName = @"excalibur";
        equipOne = @"sword";
        if([[[SettingsManager sharedSettingsManager] getString:@"sfx"] isEqualToString:@"on"])
            [[SimpleAudioEngine sharedEngine] playEffect:@"excalibur.mp3"];
    }else if([((NSString *)hillEquipment.userData) isEqualToString:@"icarus"]){
        equipmentName = @"icarus";
        if([[[SettingsManager sharedSettingsManager] getString:@"sfx"] isEqualToString:@"on"])
            [[SimpleAudioEngine sharedEngine] playEffect:@"icarus.mp3"];
        equipOne = @"wings";
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"wings.plist"];
        CCSpriteBatchNode *wingSheet = [CCSpriteBatchNode batchNodeWithFile:@"wings.png"];
        [self addChild:wingSheet];
    }
    
    equipment = [CCSprite spriteWithFile:[NSString stringWithFormat:@"%@%@", equipmentName, @".png"]];
    equipment.position = ccp(_man.position.x + [[[equipmentDic objectForKey:equipmentName] objectForKey:@"x"] intValue], _man.position.y + [[[equipmentDic objectForKey:equipmentName] objectForKey:@"y"] intValue]);
    equipment.anchorPoint = ccp(([(NSNumber *)[[equipmentDic objectForKey:equipmentName] objectForKey:@"anchorX"] floatValue]), ([(NSNumber *)[[equipmentDic objectForKey:equipmentName] objectForKey:@"anchorY"] floatValue]));
    [self addChild:equipment z:899];
    
    if(![[[SettingsManager sharedSettingsManager] getArray:@"purchases"] containsObject:equipOne]){
        oneUse = YES;
    }
    
    NSMutableArray *lightingArray = [NSMutableArray array];
    for(int i = 1; i <= [((NSString *)[[equipmentDic objectForKey:equipmentName] objectForKey:@"frames"]) intValue]; ++i) {
        [lightingArray addObject:
         [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
          [NSString stringWithFormat:[NSString stringWithFormat:@"%@%@", equipmentName, @"_bg_animation%d.png"], i]]];
    }
    CCAnimation *light = [CCAnimation animationWithFrames:lightingArray delay:0.1f];
    id lightClean = [CCCallBlock actionWithBlock:^{
        [equipmentText runAction:[CCScaleTo actionWithDuration:0.3 scale:0]];
        [self reorderChild:lighting z:479];
    }];
    id lightShow = [CCAnimate actionWithAnimation:light restoreOriginalFrame:NO];
    [self removeChild:equipmentText cleanup:YES];
    equipmentText = [CCSprite spriteWithFile:[NSString stringWithFormat:@"%@%@", equipmentName, @"_text.png"]];
    [equipmentText setPosition:ccp(winSize.width/2, winSize.height - equipmentText.contentSize.height/2 - 30)];
    [self addChild:equipmentText z:600];
    equipmentText.scale = 0;
    [equipmentText runAction:[CCScaleTo actionWithDuration:0.5 scale:1.0]];
    [self reorderChild:lighting z:481];
    CCSequence *lightAction = [CCSequence actions:lightShow, lightClean, nil];
    [lighting runAction:lightAction];
    equipAction = NO;
    icarus = NO;
    midas = NO;
    }
    
}

-(void)turnBoard{
    if(_shipPointsPerSecY < 0 && _previousPointsPerSec >= 0 && _man.position.y == jumpOrigin){
        NSMutableArray *leftturnArray = [NSMutableArray array];
        for(int i = 1; i <= 9; ++i) {
            [leftturnArray addObject:
             [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
              [NSString stringWithFormat:@"%@%@%d.png", characterName, @"Turning0", i]]];
        }
        
        leftturn = [CCAnimation animationWithFrames:leftturnArray delay:0.05f];
        [_man runAction:[CCAnimate actionWithAnimation:leftturn restoreOriginalFrame:NO]];
        
        NSMutableArray *leftboardturnArray = [NSMutableArray array];
        for(int i = 1; i <= 9; ++i) {
            [leftboardturnArray addObject:
             [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
              [NSString stringWithFormat:@"board_turning0%d.png", i]]];
        }
        
        boardleftturn = [CCAnimation animationWithFrames:leftboardturnArray delay:0.05f];
        [_board runAction:[CCAnimate actionWithAnimation:boardleftturn restoreOriginalFrame:NO]];
        _previousPointsPerSec = _shipPointsPerSecY;
    }else if (_shipPointsPerSecY > 0 && _previousPointsPerSec <= 0 && _man.position.y == jumpOrigin){
        NSMutableArray *rightturnArray = [NSMutableArray array];
        for(int i = 9; i >= 1; --i) {
            [rightturnArray addObject:
             [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
              [NSString stringWithFormat:@"%@%@%d.png", characterName, @"Turning0", i]]];
        }
        rightturn = [CCAnimation animationWithFrames:rightturnArray delay:0.05f];
        [_man runAction:[CCAnimate actionWithAnimation:rightturn restoreOriginalFrame:NO]];
        
        NSMutableArray *rightboardturnArray = [NSMutableArray array];
        for(int i = 9; i >= 1; --i) {
            [rightboardturnArray addObject:
             [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
              [NSString stringWithFormat:@"board_turning0%d.png", i]]];
        }
        
        boardrightturn = [CCAnimation animationWithFrames:rightboardturnArray delay:0.05f];
        [_board runAction:[CCAnimate actionWithAnimation:boardrightturn restoreOriginalFrame:NO]];
        _previousPointsPerSec = _shipPointsPerSecY;
    }
}

-(void)firstFall{
    //[[SimpleAudioEngine sharedEngine] playEffect:@"falling.wav"];
    [_board stopAllActions];
    [_man stopAllActions];
    [_man runAction:[CCMoveTo actionWithDuration:0.4 position:ccp(_man.position.x, _man.position.y-40)]];
    NSMutableArray *fallingArray = [NSMutableArray array];
    for(int i = 1; i <= 3; ++i) {
        [fallingArray addObject:
         [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:
          [NSString stringWithFormat:@"%@falling%d.png", characterName, i]]];
    }
    [self unschedule:@selector(updateBg)];
    CCAnimation *falling = [CCAnimation animationWithFrames:fallingArray delay:0.08f];
    [_man runAction:[CCAnimate actionWithAnimation:falling restoreOriginalFrame:NO]];
    dropShadowSprite.visible = NO;
    dropShadowBoardSprite.visible = NO;
    [trail stopSystem];
    [self unschedule:@selector(updateScoreTimer)];
    ARCH_OPTIMAL_PARTICLE_SYSTEM *fall = [ARCH_OPTIMAL_PARTICLE_SYSTEM particleWithFile:@"fall2.plist"];
    fall.positionType=kCCPositionTypeFree;
    fall.position=ccp(_man.position.x, _man.position.y-20);
    [self addChild:fall z:899];
    fallen = true;
    [self unschedule:@selector(firstFall)];
    [getUpMessage runAction:[CCScaleTo actionWithDuration:.5 scale:1]];
    [getUpMessage runAction:[CCRepeatForever actionWithAction:[CCSequence actions:[CCFadeTo actionWithDuration:.3 opacity:100], [CCDelayTime actionWithDuration:.2],[CCFadeTo actionWithDuration:.3 opacity:255], nil]]];
}

-(void)moveClouds{
    CGSize winSize = [CCDirector sharedDirector].winSize;
    
    if(cloud1.position.x > winSize.width){
        cloud1.position = ccp(-50, cloud1.position.y);
    }else{
        cloud1.position = ccp(cloud1.position.x + .8, cloud1.position.y);
    }
    
    if(cloud2.position.x < -50){
        cloud2.position = ccp(winSize.width+50, cloud2.position.y);
    }else{
        cloud2.position = ccp(cloud2.position.x - .7, cloud2.position.y);
    }
    
    if(cloud3.position.x > winSize.width){
        cloud3.position = ccp(-50, cloud3.position.y);
    }else{
        cloud3.position = ccp(cloud3.position.x + .6, cloud3.position.y);
    }
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
	[super dealloc];
}

@end
