#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "CRCoordinator.h"

NS_ASSUME_NONNULL_BEGIN

@class CRNode;
@class CRContext;

@interface CRCoordinator ()
// Private setter modifiers
@property(nonatomic, readwrite) NSString *key;
@property(nonatomic, readwrite, nullable, weak) CRContext *context;
@property(nonatomic, readwrite, nullable, weak) CRNode *node;

/// @note: Never call the init method manually - coordinators are dynamically constructed,
/// disposed and reused by @c CRContext.
- (instancetype)initWithKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
