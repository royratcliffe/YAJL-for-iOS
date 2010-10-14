// YAJL YAJLGenerator.h
//
// Copyright © 2010, Roy Ratcliffe, Pioneering Software, United Kingdom
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS," WITHOUT WARRANTY OF ANY KIND, EITHER
// EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//
//------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

#import <YAJL/yajl_gen.h>

@interface YAJLGenerator : NSObject
{
	struct yajl_gen_t *gen;
	char *indentUTF8String;
	struct
	{
		NSUInteger beautify:1;
	}
	genConfigFlags;
}

//---------------------------------------------- indent string and beautify flag

@property(copy, NS_NONATOMIC_IPHONEONLY) NSString *indentString;
@property(NS_NONATOMIC_IPHONEONLY) BOOL beautify;

//------------------------------------------------------------------- generators

// Things to note: the interface uses the term "map" for dictionaries. In this context, they are the same thing. JSON maps amount to NextStep dictionaries.

- (BOOL)generateInteger:(long)number error:(NSError **)outError;
- (BOOL)generateDouble:(double)number error:(NSError **)outError;
- (BOOL)generateString:(NSString *)string error:(NSError **)outError;
- (BOOL)generateNullWithError:(NSError **)outError;
- (BOOL)generateBool:(BOOL)yesOrNo error:(NSError **)outError;

- (BOOL)generateObject:(id)object error:(NSError **)outError;

//----------------------------------------------------------------------- buffer

- (NSString *)bufferWithError:(NSError **)outError;

@end
