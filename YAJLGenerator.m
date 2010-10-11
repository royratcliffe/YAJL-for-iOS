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

@implementation YAJLGenerator

- (id)init
{
	self = [super init];
	if (self)
	{
		gen = yajl_gen_alloc(NULL, NULL);
	}
	return self;
}

- (void)dealloc
{
	yajl_gen_free(gen);
	[super dealloc];
}

- (yajl_gen_status)generateInteger:(NSInteger)number
{
	return yajl_gen_integer(gen, number);
}

- (yajl_gen_status)generateDouble:(double_t)number
{
	return yajl_gen_double(gen, number);
}

- (yajl_gen_status)generateString:(NSString *)string
{
	const char *utf8String = [string UTF8String];
	return yajl_gen_string(gen, (const unsigned char *)utf8String, strlen(utf8String));
}

- (yajl_gen_status)generateNull
{
	return yajl_gen_null(gen);
}

- (yajl_gen_status)generateBool:(BOOL)yesOrNo
{
	return yajl_gen_bool(gen, yesOrNo);
}

- (yajl_gen_status)generateObject:(id)object
{
	yajl_gen_status status;
	if (object == nil || [object isKindOfClass:[NSNull class]])
	{
		status = [self generateNull];
	}
	else if ([object isKindOfClass:[NSArray class]])
	{
		yajl_gen_array_open(gen);
		for (id element in object)
		{
			[self generateObject:element];
		}
		yajl_gen_array_close(gen);
	}
	else
	{
		status = yajl_gen_status_ok;
	}
	return status;
}

@end
