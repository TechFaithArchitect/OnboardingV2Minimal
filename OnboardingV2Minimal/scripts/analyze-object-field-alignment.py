#!/usr/bin/env python3
"""
Script to analyze alignment between code references and actual object/field definitions.
This helps identify objects and fields referenced in code that may not exist in the metadata.
"""

import os
import re
import xml.etree.ElementTree as ET
from pathlib import Path
from collections import defaultdict

# Base directory
BASE_DIR = Path(__file__).parent.parent

# Directories to search
OBJECTS_DIR = BASE_DIR / "force-app" / "unpackaged" / "objects"
CLASSES_DIR = BASE_DIR / "force-app" / "main" / "default" / "classes"
UNPACKAGED_CLASSES_DIR = BASE_DIR / "force-app" / "unpackaged" / "classes"
LWC_DIR = BASE_DIR / "force-app" / "main" / "default" / "lwc"
UNPACKAGED_LWC_DIR = BASE_DIR / "force-app" / "unpackaged" / "lwc"

# Pattern to match custom objects in SOQL FROM clauses (more specific)
SOQL_PATTERN = re.compile(r'FROM\s+([A-Z][a-zA-Z0-9_]*__c)\b', re.IGNORECASE)
# Pattern to match object type declarations
TYPE_PATTERN = re.compile(r'(?:List<|Set<|Map<[^,]+,\s*)?([A-Z][a-zA-Z0-9_]*__c)(?:>|\[\]|\s)', re.IGNORECASE)
# Pattern to match field references (Object.Field__c)
FIELD_PATTERN = re.compile(r'\b([A-Z][a-zA-Z0-9_]*__c)\.([a-zA-Z0-9_]+__c)\b')
# Pattern for object API names in LWC (object-api-name)
LWC_OBJECT_PATTERN = re.compile(r'object-api-name=["\']([A-Z][a-zA-Z0-9_]*__c)["\']', re.IGNORECASE)

def extract_objects_from_metadata():
    """Extract all custom objects from metadata files."""
    objects = set()
    if OBJECTS_DIR.exists():
        for obj_file in OBJECTS_DIR.glob("*.object"):
            obj_name = obj_file.stem
            if obj_name.endswith("__c"):
                objects.add(obj_name)
    return objects

def extract_fields_from_object_metadata():
    """Extract all fields from object metadata files."""
    fields_by_object = defaultdict(set)
    
    if OBJECTS_DIR.exists():
        for obj_file in OBJECTS_DIR.glob("*.object"):
            obj_name = obj_file.stem
            if not obj_name.endswith("__c"):
                continue
                
            try:
                tree = ET.parse(obj_file)
                root = tree.getroot()
                
                # Register namespace
                ns = {'sf': 'http://soap.sforce.com/2006/04/metadata'}
                
                # Find all field definitions
                for field in root.findall('.//sf:fields', ns):
                    full_name = field.find('sf:fullName', ns)
                    if full_name is not None and full_name.text:
                        fields_by_object[obj_name].add(full_name.text)
            except Exception as e:
                print(f"Error parsing {obj_file}: {e}")
    
    return fields_by_object

def scan_code_for_references(directory, file_pattern="*.cls"):
    """Scan code files for object and field references."""
    objects_referenced = set()
    fields_referenced = defaultdict(set)
    
    if not directory.exists():
        return objects_referenced, fields_referenced
    
    for file_path in directory.rglob(file_pattern):
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
                
                # Find SOQL FROM clauses (most reliable)
                for match in SOQL_PATTERN.findall(content):
                    objects_referenced.add(match)
                
                # Find type declarations
                for match in TYPE_PATTERN.findall(content):
                    if match.endswith('__c'):
                        objects_referenced.add(match)
                
                # Find field references (Object.Field__c)
                for match in FIELD_PATTERN.findall(content):
                    obj_name, field_name = match
                    if obj_name.endswith('__c') and field_name.endswith('__c'):
                        fields_referenced[obj_name].add(field_name)
                        objects_referenced.add(obj_name)
                    
        except Exception as e:
            print(f"Error reading {file_path}: {e}")
    
    return objects_referenced, fields_referenced

def scan_js_for_references(directory):
    """Scan JavaScript/LWC files for object references."""
    objects_referenced = set()
    
    if not directory.exists():
        return objects_referenced
    
    for file_path in directory.rglob("*.js"):
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
                
                # Find object API names in LWC
                for match in LWC_OBJECT_PATTERN.findall(content):
                    objects_referenced.add(match)
                    
        except Exception as e:
            print(f"Error reading {file_path}: {e}")
    
    # Also check HTML files for object-api-name
    for file_path in directory.rglob("*.html"):
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
                
                # Find object API names in LWC HTML
                for match in LWC_OBJECT_PATTERN.findall(content):
                    objects_referenced.add(match)
                    
        except Exception as e:
            print(f"Error reading {file_path}: {e}")
    
    return objects_referenced

def generate_report():
    """Generate alignment report."""
    print("=" * 80)
    print("OBJECT AND FIELD ALIGNMENT ANALYSIS")
    print("=" * 80)
    print()
    
    # Extract metadata
    print("📦 Extracting metadata from object files...")
    existing_objects = extract_objects_from_metadata()
    existing_fields = extract_fields_from_object_metadata()
    
    print(f"   Found {len(existing_objects)} custom objects in metadata")
    print(f"   Found fields for {len(existing_fields)} objects")
    print()
    
    # Scan code
    print("🔍 Scanning code for object and field references...")
    all_objects_referenced = set()
    all_fields_referenced = defaultdict(set)
    
    # Scan Apex classes
    obj_refs, field_refs = scan_code_for_references(CLASSES_DIR, "*.cls")
    all_objects_referenced.update(obj_refs)
    for obj, fields in field_refs.items():
        all_fields_referenced[obj].update(fields)
    
    obj_refs, field_refs = scan_code_for_references(UNPACKAGED_CLASSES_DIR, "*.cls")
    all_objects_referenced.update(obj_refs)
    for obj, fields in field_refs.items():
        all_fields_referenced[obj].update(fields)
    
    # Scan LWC
    obj_refs = scan_js_for_references(LWC_DIR)
    all_objects_referenced.update(obj_refs)
    
    obj_refs = scan_js_for_references(UNPACKAGED_LWC_DIR)
    all_objects_referenced.update(obj_refs)
    
    print(f"   Found {len(all_objects_referenced)} unique object references in code")
    print()
    
    # Compare
    print("=" * 80)
    print("OBJECT ALIGNMENT ANALYSIS")
    print("=" * 80)
    print()
    
    objects_in_code_not_in_metadata = all_objects_referenced - existing_objects
    objects_in_metadata_not_in_code = existing_objects - all_objects_referenced
    
    print(f"✅ Objects in both code and metadata: {len(existing_objects & all_objects_referenced)}")
    print(f"⚠️  Objects in code but NOT in metadata: {len(objects_in_code_not_in_metadata)}")
    print(f"ℹ️  Objects in metadata but NOT in code: {len(objects_in_metadata_not_in_code)}")
    print()
    
    if objects_in_code_not_in_metadata:
        print("⚠️  OBJECTS REFERENCED IN CODE BUT NOT IN METADATA:")
        print("-" * 80)
        for obj in sorted(objects_in_code_not_in_metadata):
            print(f"   - {obj}")
        print()
    
    if objects_in_metadata_not_in_code:
        print("ℹ️  OBJECTS IN METADATA BUT NOT REFERENCED IN CODE:")
        print("-" * 80)
        for obj in sorted(objects_in_metadata_not_in_code):
            print(f"   - {obj}")
        print()
    
    # Field analysis
    print("=" * 80)
    print("FIELD ALIGNMENT ANALYSIS")
    print("=" * 80)
    print()
    
    missing_fields = defaultdict(set)
    for obj_name, fields in all_fields_referenced.items():
        if obj_name in existing_fields:
            missing = fields - existing_fields[obj_name]
            if missing:
                missing_fields[obj_name] = missing
    
    if missing_fields:
        print("⚠️  FIELDS REFERENCED IN CODE BUT NOT IN METADATA:")
        print("-" * 80)
        for obj_name in sorted(missing_fields.keys()):
            print(f"   {obj_name}:")
            for field in sorted(missing_fields[obj_name]):
                print(f"      - {field}")
        print()
    else:
        print("✅ All referenced fields exist in metadata")
        print()
    
    # Summary
    print("=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print()
    print(f"Total custom objects in metadata: {len(existing_objects)}")
    print(f"Total objects referenced in code: {len(all_objects_referenced)}")
    print(f"Objects with alignment issues: {len(objects_in_code_not_in_metadata)}")
    print(f"Objects with missing fields: {len(missing_fields)}")
    print()
    
    if objects_in_code_not_in_metadata or missing_fields:
        print("⚠️  ACTION REQUIRED:")
        print("   - Review objects referenced in code but not in metadata")
        print("   - These may need to be added to package.xml or created")
        print("   - Review fields referenced but not defined")
    else:
        print("✅ Code appears to be aligned with metadata!")

if __name__ == "__main__":
    generate_report()

