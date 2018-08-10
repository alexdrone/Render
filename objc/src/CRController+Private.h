#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CRNode;

@interface CRController <P, S> ()
// Private setter modifiers
@property(nonatomic, readwrite) NSString *key;
@property(nonatomic, readwrite, nullable, weak) CRContext *context;
@property(nonatomic, readwrite, nullable, weak) CRNode *node;

/// @note: Never call the init method manually - controllers are dynamically constructed,
/// disposed and reused by @c CRContext.
- (instancetype)initWithKey:(NSString*)key;

@end

NS_ASSUME_NONNULL_END
