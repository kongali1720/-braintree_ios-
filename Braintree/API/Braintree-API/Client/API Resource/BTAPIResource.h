@import Foundation;

extern NSString *const BTAPIResourceErrorDomain;

typedef NS_ENUM(NSInteger, BTAPIResourceErrorCode) {
    BTAPIResourceErrorUnknown,
    BTAPIResourceErrorResourceSpecificationInvalid,
    BTAPIResourceErrorResourceDictionaryMissingKey,
    BTAPIResourceErrorResourceDictionaryInvalid,
    BTAPIResourceErrorResourceDictionaryNestedResourceInvalid,
};

@protocol BTAPIResourceValueType;

id<BTAPIResourceValueType> BTAPIResourceValueTypeString(SEL setter);
id<BTAPIResourceValueType> BTAPIResourceValueTypeStringSet(SEL setter);
id<BTAPIResourceValueType> BTAPIResourceValueTypeAPIResource(SEL setter, Class BTAPIResourceClass);
id<BTAPIResourceValueType> BTAPIResourceValueTypeOptional(id<BTAPIResourceValueType> APIResourceValueType);

@interface BTAPIResource : NSObject

+ (id)modelWithAPIDictionary:(NSDictionary *)APIDictionary error:(NSError *__autoreleasing *)error;

+ (NSDictionary *)APIDictionaryWithModel:(id)resource;


#pragma mark Methods to Override

+ (Class)resourceModelClass;

+ (NSDictionary *)APIFormat;

@end
