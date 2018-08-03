#ifndef CRController_Private_h
#define CRController_Private_h

@interface CRController ()
// Private setter modifiers
@property(nonatomic, readwrite) NSString *key;

/// @note: Never call the init method manually - controllers are dynamically constructed,
/// disposed and reused by @c CRContext.
- (instancetype)initWithKey:(NSString*)key;

@end

#endif /* CRController_Private_h */
