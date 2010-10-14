// YAJL YAJLParser.h
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

#import <YAJL/yajl_parse.h>

@interface YAJLParser : NSObject
{
	struct yajl_handle_t *handle;
	struct
	{
		NSUInteger allowComments:1;
		NSUInteger checkUTF8:1;
	}
	parserConfigFlags;
	NSMutableArray *stack;
	id rootObject;
}

@property(NS_NONATOMIC_IPHONEONLY) BOOL allowComments;
@property(NS_NONATOMIC_IPHONEONLY) BOOL checkUTF8;

@property(retain, NS_NONATOMIC_IPHONEONLY) id rootObject;

- (BOOL)parseString:(NSString *)string error:(NSError **)outError;
- (BOOL)parseCompleteWithError:(NSError **)outError;

@end
