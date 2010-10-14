// YAJL YAJLParser.m
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

#import "YAJLParser.h"
#import "YAJLErrorDomain.h"

// We need yajl_parser header for the complete definition of the yajl_handle_t
// structure. Note, there are two similar sounding headers: yajl_parse and
// yajl_parser. They are not the same. The latter header with an additional "r"
// contains some internal definitions not exposed by the public interfaces, such
// as yajl_handle_t. These headers are needed so that YAJLParser can query the
// current parser state, asking yajl_bs_current(handle->stateStack) and such.
#import "yajl_lex.h"
#import "yajl_parser.h"

@interface YAJLParser(Private)

- (struct yajl_handle_t *)handle;
- (yajl_state)currentState;
- (yajl_state)previousState;
- (int)emitObject:(id)object;
- (int)emitKey:(NSString *)key;
- (int)startMap;
- (int)endMap;
- (int)startArray;
- (int)endArray;
- (int)endWithObject:(id)object;

@end

@implementation YAJLParser

//------------------------------------------------------------------------------
#pragma mark                                allow comments and check UTF-8 flags
//------------------------------------------------------------------------------

- (BOOL)allowComments
{
	return parserConfigFlags.allowComments;
}

- (BOOL)checkUTF8
{
	return parserConfigFlags.checkUTF8;
}

- (void)setAllowComments:(BOOL)flag
{
	parserConfigFlags.allowComments = flag;
}

- (void)setCheckUTF8:(BOOL)flag
{
	parserConfigFlags.checkUTF8 = flag;
}

//------------------------------------------------------------------------------
#pragma mark                                                             parsing
//------------------------------------------------------------------------------

@synthesize rootObject;

- (void)dealloc
{
	// Releasing the parser does not release the root object. You may want to
	// continue using the root object after you no longer need the parser. That
	// would be normal. So, rather than release, just set the root-object
	// property to nil. In effect, nil'ing auto-releases the root object. It
	// will de-allocate when the enclosing auto-release pool flushes.
	[self setRootObject:nil];
	
	if (handle)
	{
		yajl_free(handle);
	}
	[stack release];
	[super dealloc];
}

static BOOL YAJLParseError(yajl_status status, NSError **outError)
{
	BOOL yes = status == yajl_status_ok;
	if (!yes && outError && *outError == nil)
	{
		*outError = [NSError errorWithDomain:YAJLErrorDomain code:status userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithUTF8String:yajl_status_to_string(status)] forKey:NSLocalizedDescriptionKey]];
	}
	return yes;
}

- (BOOL)parseString:(NSString *)string error:(NSError **)outError
{
	const char *UTF8String = [string UTF8String];
	size_t length = strlen(UTF8String);
	return YAJLParseError(yajl_parse([self handle], (const unsigned char *)UTF8String, length), outError);
}

- (BOOL)parseData:(NSData *)data error:(NSError **)outError
{
	return YAJLParseError(yajl_parse([self handle], [data bytes], [data length]), outError);
}

- (BOOL)parseCompleteWithError:(NSError **)outError
{
	return YAJLParseError(yajl_parse_complete(handle), outError);
}

@end

//------------------------------------------------------------------------------
#pragma mark                                                           callbacks
//------------------------------------------------------------------------------

static int YAJLNull(void *context)
{
	return [(YAJLParser *)context emitObject:[NSNull null]];
}

static int YAJLBoolean(void *context, int boolValue)
{
	return [(YAJLParser *)context emitObject:[NSNumber numberWithBool:boolValue]];
}

static int YAJLInteger(void *context, long integerValue)
{
	return [(YAJLParser *)context emitObject:[NSNumber numberWithLong:integerValue]];
}

static int YAJLDouble(void *context, double doubleValue)
{
	return [(YAJLParser *)context emitObject:[NSNumber numberWithDouble:doubleValue]];
}

static int YAJLString(void *context, const unsigned char *string, unsigned int length)
{
	return [(YAJLParser *)context emitObject:[[[NSString alloc] initWithBytes:string length:length encoding:NSUTF8StringEncoding] autorelease]];
}

static int YAJLStartMap(void *context)
{
	return [(YAJLParser *)context startMap];
}

static int YAJLMapKey(void *context, const unsigned char *string, unsigned int length)
{
	return [(YAJLParser *)context emitKey:[[[NSString alloc] initWithBytes:string length:length encoding:NSUTF8StringEncoding] autorelease]];
}

static int YAJLEndMap(void *context)
{
	return [(YAJLParser *)context endMap];
}

static int YAJLStartArray(void *context)
{
	return [(YAJLParser *)context startArray];
}

static int YAJLEndArray(void *context)
{
	return [(YAJLParser *)context endArray];
}

static yajl_callbacks YAJLCallbacks =
{
	YAJLNull,
	YAJLBoolean,
	YAJLInteger,
	YAJLDouble,
	
	NULL,
	
	YAJLString,
	
	YAJLStartMap,
	YAJLMapKey,
	YAJLEndMap,
	
	YAJLStartArray,
	YAJLEndArray,
};

@implementation YAJLParser(Private)

- (struct yajl_handle_t *)handle
{
	if (handle == NULL)
	{
		yajl_parser_config config;
		config.allowComments = parserConfigFlags.allowComments;
		config.checkUTF8 = parserConfigFlags.checkUTF8;
		handle = yajl_alloc(&YAJLCallbacks, &config, NULL, self);
		
		if (handle)
		{
			stack = [[NSMutableArray alloc] init];
		}
	}
	return handle;
}

- (yajl_state)currentState
{
	return yajl_bs_current([self handle]->stateStack);
}

- (yajl_state)previousState
{
	return handle->stateStack.used >= 2 ? handle->stateStack.stack[handle->stateStack.used - 2] : -1;
}

- (int)emitObject:(id)object
{
	const yajl_state state = [self currentState];
	// Use the state to determine how to emit the object. It depends on the
	// current context: within a map, at the start of or within the middle of an
	// array, or at the very start of the parse. Accept all these possibilities.
	//
	// Footnote: Storing the state in a variable is redundant so far as concerns
	// the compiler. With optimisation enabled, the compiler removes the
	// redundancy. However, seeing the current state in the stack context proves
	// helpful when debugging.
	switch (state)
	{
			NSString *key;
			
		case yajl_state_map_need_val:
			// In this state, the parser state machine has seen a key and now
			// awaits a value. Together, the key and value comprise a new
			// key-value pair for the map. When the parser sees a key, our
			// wrapper pushes the key to the top of the stack, temporarily. Pop
			// the key then add the key-value pair to the map at the top of the
			// stack.
			//
			//	[stack count - 2]		a mutable dictionary (a map)
			//	[stack count - 1]		a key string
			//
			key = [stack lastObject];
			[stack removeLastObject];
			
			[(NSMutableDictionary *)[stack lastObject] setObject:object forKey:key];
			break;
			
		case yajl_state_array_start:
		case yajl_state_array_need_val:
			// In these states, the parser has either started a new array or has
			// seen a comma delimiter and awaits another value. The new value
			// has arrived. Add it to the array at the top of the stack.
			//
			//	[stack count - 1]		a mutable array
			//
			[(NSMutableArray *)[stack lastObject] addObject:object];
			break;
			
		case yajl_state_start:
			[self setRootObject:object];
	}
	return 1;
}

- (int)emitKey:(NSString *)key
{
	[stack addObject:key];
	return 1;
}

- (int)startMap
{
	[stack addObject:[NSMutableDictionary dictionary]];
	return 1;
}

- (int)endMap
{
	//
	//	[stack count - 1]		a mutable dictionary (a map)
	//
	NSDictionary *object = [NSDictionary dictionaryWithDictionary:[stack lastObject]];
	[stack removeLastObject];
	
	return [self endWithObject:object];
}

- (int)startArray
{
	[stack addObject:[NSMutableArray array]];
	return 1;
}

- (int)endArray
{
	NSArray *object = [NSArray arrayWithArray:[stack lastObject]];
	[stack removeLastObject];
	
	return [self endWithObject:object];
}

- (int)endWithObject:(id)object
{
	const yajl_state state = [self previousState];
	switch (state)
	{
			NSString *key;
			
		case yajl_state_map_got_val:
			key = [stack lastObject];
			[stack removeLastObject];
			
			[(NSMutableDictionary *)[stack lastObject] setObject:object forKey:key];
			break;
			
		case yajl_state_array_got_val:
			[(NSMutableArray *)[stack lastObject] addObject:object];
			break;
			
		case yajl_state_parse_complete:
			[self setRootObject:object];
	}
	return 1;
}

@end
