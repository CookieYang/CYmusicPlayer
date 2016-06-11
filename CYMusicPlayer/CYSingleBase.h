//
//  CYSingleBase.h
//  test
//
//  Created by 杨涛 on 16/5/22.
//  Copyright © 2016年 CookieYang. All rights reserved.
//



#define CYSingle_h(name) +(instancetype) sharedSingle##name;

#if  __has_feature(objc_arc)
#define CYSingle_m(name) static id _instance;\
\
+ (instancetype) sharedSingle##name {\
    static dispatch_once_t onceToken;\
    dispatch_once(&onceToken, ^{\
        _instance = [[self alloc] init];\
    });\
    return _instance;\
}\
\
+ (instancetype) allocWithZone:(struct _NSZone *)zone {\
    static dispatch_once_t onceToken;\
    dispatch_once(&onceToken, ^{\
        _instance = [super allocWithZone: zone];\
    });\
    return _instance;\
}\
\
- (instancetype) copyWithZone:(NSZone *)zone {\
    return _instance;\
}\
\
- (instancetype) mutableCopy {\
    return _instance;\
}\
\
- (instancetype) init {\
    return _instance;\
}

#else

#define CYSingle_m(name) static id _instance;\
\
+ (instancetype) sharedSingle##name {\
static dispatch_once_t onceToken;\
dispatch_once(&onceToken, ^{\
_instance = [[self alloc] init];\
});\
return _instance;\
}\
\
+ (instancetype) allocWithZone:(struct _NSZone *)zone {\
static dispatch_once_t onceToken;\
dispatch_once(&onceToken, ^{\
_instance = [super allocWithZone: zone];\
});\
return _instance;\
}\
\
- (instancetype) copyWithZone:(NSZone *)zone {\
return _instance;\
}\
\
- (instancetype) mutableCopy {\
return _instance;\
}\
\
- (instancetype) init {\
return _instance;\
}\
\
- (instancetype) retain {\
    return _instance;\
}\
\
- (NSUInteger)retainCount {\
    return 1;\
}\
\
- (oneway void)release {\
    \
}\
\
- (instancetype)autorelease {\
    return _instance;\
}
#endif
