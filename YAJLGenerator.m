// YAJL YAJLGenerator.m
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

#import "YAJLGenerator.h"
#import "YAJLErrorDomain.h"

@interface YAJLGenerator(Private)

/*!
 * Constructs the generator implementation lazily. Reason for the laziness: it
 * lets you set up the indent string and beautify flag prior to use. Once you
 * start using the generator however, these configuration items become
 * hardwired.
 */
- (struct yajl_gen_t *)gen;

@end

@implementation YAJLGenerator

- (void)dealloc
{
	if (gen)
	{
		yajl_gen_free(gen);
	}
	free(indentUTF8String);
	[super dealloc];
}

//------------------------------------------------------------------------------
#pragma mark                                     indent string and beautify flag
//------------------------------------------------------------------------------

- (NSString *)indentString
{
	return [NSString stringWithUTF8String:indentUTF8String];
}

/*!
 * Do not alter the indent string if the generator exists. You can only alter
 * the configuration items prior to use. Set up the generator first, then use
 * it. When you start to use the generator, set-up methods become no-operations.
 */
- (void)setIndentString:(NSString *)string
{
	if (gen == NULL)
	{
		free(indentUTF8String);
		indentUTF8String = strdup([string UTF8String]);
	}
}

- (BOOL)beautify
{
	return genConfigFlags.beautify;
}

- (void)setBeautify:(BOOL)yesOrNo
{
	genConfigFlags.beautify = yesOrNo;
}

//------------------------------------------------------------------------------
#pragma mark                                                          generators
//------------------------------------------------------------------------------

/*!
 * Handles YAJL status; answers with YES or NO, and generates an error if
 * NO. All the generator methods answer YES on success, NO on failure. If they
 * fail and you supply a pointer to an NSError pointer equal to nil, the
 * generator methods create a new error. The error code equals the generator
 * status, a non-zero value.
 */
static BOOL YAJLGenerateError(yajl_gen_status status, NSError **outError)
{
	BOOL yes = status == yajl_gen_status_ok;
	if (!yes && outError && *outError == nil)
	{
		*outError = [NSError errorWithDomain:YAJLErrorDomain code:status userInfo:nil];
	}
	return yes;
}

- (BOOL)generateInteger:(long)number error:(NSError **)outError
{
	return YAJLGenerateError(yajl_gen_integer([self gen], number), outError);
}

- (BOOL)generateDouble:(double)number error:(NSError **)outError
{
	return YAJLGenerateError(yajl_gen_double([self gen], number), outError);
}

- (BOOL)generateString:(NSString *)string error:(NSError **)outError
{
	const char *UTF8String = [string UTF8String];
	return YAJLGenerateError(yajl_gen_string([self gen], (const unsigned char *)UTF8String, strlen(UTF8String)), outError);
}

- (BOOL)generateNullWithError:(NSError **)outError
{
	return YAJLGenerateError(yajl_gen_null([self gen]), outError);
}

- (BOOL)generateBool:(BOOL)yesOrNo error:(NSError **)outError
{
	return YAJLGenerateError(yajl_gen_bool([self gen], yesOrNo), outError);
}

- (BOOL)generateMap:(NSDictionary *)dictionary error:(NSError **)outError
{
	BOOL yes = YAJLGenerateError(yajl_gen_map_open([self gen]), outError);
	if (yes)
	{
		for (id key in dictionary)
		{
			yes = [self generateObject:key error:outError];
			if (!yes) return yes;
			
			yes = [self generateObject:[dictionary objectForKey:key] error:outError];
			if (!yes) return yes;
		}
		yes = YAJLGenerateError(yajl_gen_map_close([self gen]), outError);
	}
	return yes;
}

- (BOOL)generateArray:(NSArray *)array error:(NSError **)outError
{
	BOOL yes = YAJLGenerateError(yajl_gen_array_open([self gen]), outError);
	if (yes)
	{
		for (id element in array)
		{
			yes = [self generateObject:element error:outError];
			if (!yes) return yes;
		}
		yes = YAJLGenerateError(yajl_gen_array_close([self gen]), outError);
	}
	return yes;
}

- (BOOL)generateObject:(id)object error:(NSError **)outError
{
	BOOL yes;
	if (object == nil || [object isKindOfClass:[NSNull class]])
	{
		yes = [self generateNullWithError:outError];
	}
	else if ([object isKindOfClass:[NSNumber class]])
	{
		const char *objCType = [object objCType];
		// Fold all the integer formats available for NSNumber to a plain
		// integer, a signed integer or to be more specific a signed long. Long
		// is the basic type accepted by the underlying implementation. Unsigned
		// values greater than LONG_MAX become type cast to the equivalent
		// signed value. Values with wider bit-width than long become
		// truncated. This includes long long and possibly NSInteger depending
		// on architecture.
		static const char *integerEncodings[] =
		{
			// signed
			@encode(char),
			@encode(short),
			@encode(int),
			@encode(long),
			@encode(long long),
			// unsigned
			@encode(unsigned char),
			@encode(unsigned short),
			@encode(unsigned int),
			@encode(unsigned long),
			@encode(unsigned long long),
		};
#define DIMOF(array) (sizeof(array)/sizeof((array)[0]))
		NSUInteger i;
		for (i = 0; i < DIMOF(integerEncodings) && strcmp(objCType, integerEncodings[i]); i++);
		if (i < DIMOF(integerEncodings))
		{
			yes = [self generateInteger:[object longValue] error:outError];
		}
		else if (strcmp(objCType, @encode(double)) == 0 || strcmp(objCType, @encode(float)) == 0)
		{
			yes = [self generateDouble:[object doubleValue] error:outError];
		}
		else if (strcmp(objCType, @encode(BOOL)) == 0)
		{
			yes = [self generateBool:[object boolValue] error:outError];
		}
	}
	else if ([object isKindOfClass:[NSString class]])
	{
		yes = [self generateString:object error:outError];
	}
	else if ([object isKindOfClass:[NSDictionary class]])
	{
		yes = [self generateMap:object error:outError];
	}
	else if ([object isKindOfClass:[NSArray class]])
	{
		yes = [self generateArray:object error:outError];
	}
	else
	{
		yes = NO;
	}
	return yes;
}

//------------------------------------------------------------------------------
#pragma mark                                                              buffer
//------------------------------------------------------------------------------

- (NSString *)bufferWithError:(NSError **)outError
{
	NSString *string;
	const unsigned char *buf;
	unsigned int len;
	if (YAJLGenerateError(yajl_gen_get_buf(gen, &buf, &len), outError))
	{
		string = [NSString stringWithUTF8String:(const char *)buf];
	}
	else
	{
		string = nil;
	}
	return string;
}

@end

@implementation YAJLGenerator(Private)

- (struct yajl_gen_t *)gen
{
	if (gen == NULL)
	{
		yajl_gen_config config;
		config.beautify = genConfigFlags.beautify;
		config.indentString = indentUTF8String;
		gen = yajl_gen_alloc(&config, NULL);
	}
	return gen;
}

@end
