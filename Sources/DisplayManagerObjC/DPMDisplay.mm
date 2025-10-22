#import "DPMDisplay.h"

#import <CoreFoundation/CoreFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/graphics/IOGraphicsLib.h>



static void print_entry(io_registry_entry_t entry);
static void traverse_entry(io_registry_entry_t entry);



@implementation DPMDisplay

+ (void)playground
{
	io_iterator_t serialPortIterator = 0;
//	ioreg -w0 -irc IOFramebuffer
	CFMutableDictionaryRef matching = IOServiceMatching("IOGraphicsDevice"); /* Works with IODisplay and IODisplayConnect, but we do not get the same value as CGDisplayIOServicePort. */
	if (IOServiceGetMatchingServices(kIOMasterPortDefault, matching, &serialPortIterator) != KERN_SUCCESS || serialPortIterator == 0) {
		NSLog(@"Failed getting matching services.");
		return;
	}
	
	CGDirectDisplayID mainDisplayID = CGMainDisplayID();
	io_object_t displayService = 0;
	
	for (io_object_t ioService = IOIteratorNext(serialPortIterator); ioService != 0; ioService = IOIteratorNext(serialPortIterator)) {
		NSDictionary *info = (__bridge NSDictionary *)IODisplayCreateInfoDictionary(ioService, kIODisplayOnlyPreferredName);
		/* TODO: Should the dictionary be released? (Yes, it should.) */
		if (info == NULL) {
			NSLog(@"Failed retrieving IO info dictionary for IO service. Skipping this service.");
			continue;
		}
		
		uint32_t vendorID = 0, productID = 0, serial = 0;
		NSNumber  *vendorIDNumber = [info valueForKey:@kDisplayVendorID];
		NSNumber *productIDNumber = [info valueForKey:@kDisplayProductID];
		NSNumber    *serialNumber = [info valueForKey:@kDisplaySerialNumber];
		if ( vendorIDNumber != NULL)  vendorID = [ vendorIDNumber intValue];
		if (productIDNumber != NULL) productID = [productIDNumber intValue];
		if (   serialNumber != NULL)    serial = [   serialNumber intValue];
		
		/* Note: We take the first that matches w/o checking if another would (which should never happen). */
		if (CGDisplayVendorNumber(mainDisplayID) == vendorID &&
			 CGDisplayModelNumber(mainDisplayID)  == productID &&
			 CGDisplaySerialNumber(mainDisplayID) == serial)
		{
			displayService = ioService;
			break;
		}
	}
	if (displayService == 0) {
		NSLog(@"Failed getting the display service with the complicated method…");
		goto err;
	} else if (displayService != CGDisplayIOServicePort(mainDisplayID)) {
		NSLog(@"Huh?");
		goto err;
	} else {
		NSLog(@"Found DisplayService using a super complicated method! And it matches the one found using a simple function call.");
	}
	CFDictionaryRef params;
	if (IODisplayCopyParameters(displayService, 0, &params) == kIOReturnSuccess) {
		NSLog(@"%@", params);
	} else {
		NSLog(@"Failed getting the params.");
	}
	NSLog(@"%@", IODisplayCreateInfoDictionary(displayService, 0));
	
err:
	IOObjectRelease(serialPortIterator);
	return;
}

+ (void)printAllIORegistry
{
	mach_port_t masterPort;
	io_registry_entry_t rootEntry;
	
	IOMasterPort(MACH_PORT_NULL, &masterPort);
	rootEntry = IORegistryGetRootEntry(masterPort);
	print_entry(rootEntry);
	return;
}

@end




static void print_cf_string(CFStringRef cf_string) {
	char * buffer;
	CFIndex len = CFStringGetLength(cf_string);
	buffer = (char *) malloc(sizeof(char) * len + 1);
	CFStringGetCString(cf_string, buffer, len + 1,
							 CFStringGetSystemEncoding());
	printf("%s", buffer);
	free(buffer);
}
static void print_cf_number(CFNumberRef cf_number) {
	int number;
	/* TODO rather test CFNumberType, than approximate to int */
	CFNumberGetValue(cf_number, kCFNumberIntType, &number);
	printf("%d", number);
}

static void print_cf_type(CFTypeRef cf_type) {
	CFTypeID type_id;
	
	type_id = (CFTypeID)CFGetTypeID(cf_type);
	if (type_id == CFStringGetTypeID()) {
		print_cf_string((CFStringRef)cf_type);
	} else if (type_id == CFNumberGetTypeID()) {
		print_cf_number((CFNumberRef)cf_type);
	} else {
		/* unknown Type (TODO) */
		printf("<");
		print_cf_string(CFCopyTypeIDDescription(type_id));
		printf(">");
		/* CFSHOW(type_id) for or
		 * print_cf_string(CFCopyDescription(type_id))
		 */
	}
}
static void print_properties(io_registry_entry_t entry) {
	CFMutableDictionaryRef properties;
	CFIndex count;
	CFTypeRef *keys;
	CFTypeRef *values;
	int i;
	
	IORegistryEntryCreateCFProperties(entry, &properties,
												 kCFAllocatorDefault, kNilOptions);
	count = CFDictionaryGetCount(properties);
	keys = (CFTypeRef *) malloc(sizeof(CFTypeRef) * count);
	values = (CFTypeRef *) malloc(sizeof(CFTypeRef) * count);
	CFDictionaryGetKeysAndValues(properties,
										  (const void **) keys, (const void **) values);
	for (i = 0; i < count; i++) {
		printf("\t");
		print_cf_type(keys[i]);
		printf(": ");
		print_cf_type(values[i]);
		printf("\n");
	}
}

static void print_entry(io_registry_entry_t entry) {
	io_name_t name;
	IORegistryEntryGetName(entry, name);
	printf("Starting %s\n", name);
	print_properties(entry);
	traverse_entry(entry);
	printf("Finishing %s\n", name);
}

static void traverse_entry(io_registry_entry_t entry) {
	io_iterator_t childIterator;
	io_object_t child;
	IORegistryEntryGetChildIterator(entry, kIOServicePlane, &childIterator);
	while ((child = IOIteratorNext(childIterator))) {
		print_entry(child);
		IOObjectRelease(child);
	}
	IOObjectRelease(childIterator);
}
