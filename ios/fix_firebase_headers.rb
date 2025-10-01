#!/usr/bin/env ruby

# Script to fix Firebase header imports for modular framework compatibility

def fix_firebase_headers
  # Find all Firebase header files that need fixing
  firebase_header_files = [
    "/Users/rishabhsingh/.pub-cache/hosted/pub.dev/firebase_storage-11.6.5/ios/Classes/FLTTaskStateChannelStreamHandler.h",
    "/Users/rishabhsingh/.pub-cache/hosted/pub.dev/firebase_auth-4.16.0/ios/Classes/Private/FLTAuthStateChannelStreamHandler.h",
    "/Users/rishabhsingh/.pub-cache/hosted/pub.dev/firebase_auth-4.16.0/ios/Classes/Private/PigeonParser.h",
    "/Users/rishabhsingh/.pub-cache/hosted/pub.dev/firebase_auth-4.16.0/ios/Classes/Private/FLTIdTokenChannelStreamHandler.h",
    "/Users/rishabhsingh/.pub-cache/hosted/pub.dev/firebase_auth-4.16.0/ios/Classes/Private/FLTPhoneNumberVerificationStreamHandler.h",
    "/Users/rishabhsingh/.pub-cache/hosted/pub.dev/firebase_auth-4.16.0/ios/Classes/Public/FLTFirebaseAuthPlugin.h"
  ]
  
  firebase_header_files.each do |file_path|
    if File.exist?(file_path)
      puts "Fixing #{file_path}"
      content = File.read(file_path)
      
      # Replace Firebase.h import with umbrella header using quotes
      content.gsub!(/#import <Firebase\/Firebase\.h>/, '#import "Firebase.h"')
      
      # Remove FirebaseStorage imports since it's a Swift framework
      content.gsub!(/#import <FirebaseStorage\/FirebaseStorage\.h>/, '')
      content.gsub!(/#import "FirebaseStorage\.h"/, '')
      
      # Fix other Firebase imports to use quotes
      content.gsub!(/#import <FirebaseCore\/FirebaseCore\.h>/, '#import "FirebaseCore.h"')
      content.gsub!(/#import <FirebaseAuth\/FirebaseAuth\.h>/, '#import "FirebaseAuth.h"')
      
      File.write(file_path, content)
      puts "Fixed #{file_path}"
    else
      puts "File not found: #{file_path}"
    end
  end
end

fix_firebase_headers
