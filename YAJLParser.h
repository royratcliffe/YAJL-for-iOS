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

//----------------------------------------- allow comments and check UTF-8 flags

@property(NS_NONATOMIC_IPHONEONLY) BOOL allowComments;
@property(NS_NONATOMIC_IPHONEONLY) BOOL checkUTF8;

//---------------------------------------------------------------------- parsing

/*!
 * Accesses the root object, typically after parsing completes. Note that the
 * root object can be a non-aggregate type (null, a boolean, an integer, a
 * double or a string) as well as a map or an array. The root of the parsed JSON
 * text does not necessarily specify a collection of objects.
 */
@property(retain, NS_NONATOMIC_IPHONEONLY) id rootObject;

/*!
 * Sends JSON text strings to the parser. You can send this message multiple
 * times, such as when you read incoming JSON partially in blocks through an
 * Internet connection or from files via a read buffer. However, in those cases,
 * using -parseData:error: will prove wiser because UTF-8 encodings may not
 * always align against buffer boundaries. Parsing data rather than strings
 * correctly realigns the multi-byte character codes. Be advised therefore,
 * converting buffered subsections of the data to UTF-8 may throw up some
 * decoding problems.
 */
- (BOOL)parseString:(NSString *)string error:(NSError **)outError;
- (BOOL)parseData:(NSData *)data error:(NSError **)outError;
- (BOOL)parseCompleteWithError:(NSError **)outError;

@end
