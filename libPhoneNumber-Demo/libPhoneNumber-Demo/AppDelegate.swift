//
//  AppDelegate.swift
//  libPhoneNumber-Demo
//
//  Created by Rastaar Haghi on 7/17/20.
//  Copyright © 2020 Google LLC. All rights reserved.
//

import UIKit
import JavaScriptCore

extension Data {
    public var bytes: [UInt8]
    {
        return [UInt8](self)
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Override point for customization after application launch.
      self.setup()
    return true
  }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    
    func setup() {
        // Create JavaScript context.
        let context = JSContext()!
        context.exceptionHandler = { _, exception in
          fputs("Javascript exception thrown: \(exception!)\n", __stderrp)
        //  exit(1)
        }

        // Load required dependencies.
        let googleClosure = URL(
          string: "http://cdn.rawgit.com/google/closure-library/master/closure/goog/base.js")!
        loadJS(from: googleClosure, to: context)

        let jQuery = URL(string: "http://code.jquery.com/jquery-1.8.3.min.js")!
        loadJS(from: jQuery, to: context)

        // Evaluate requires.
        let requires = """
          goog.require('goog.proto2.Message');
          goog.require('goog.dom');
          goog.require('goog.json');
          goog.require('goog.array');
          goog.require('goog.proto2.ObjectSerializer');
          goog.require('goog.string.StringBuffer');
          goog.require('i18n.phonenumbers.metadata');
          """
        context.evaluateScript(requires)

        // Load metadata file from GitHub.
        let phoneMetadata = URL(string: "https://raw.githubusercontent.com/google/libphonenumber/master/javascript/i18n/phonenumbers/metadata.js")!
        let phoneMetadataForTesting = URL(string: "https://raw.githubusercontent.com/google/libphonenumber/master/javascript/i18n/phonenumbers/metadatafortesting.js")!
        let shortNumberMetadata = URL(string: "https://raw.githubusercontent.com/google/libphonenumber/master/javascript/i18n/phonenumbers/shortnumbermetadata.js")!

        let baseURL = self.getDocumentsDirectory().appendingPathComponent("generatedJSON")
        try? FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
        
        // Phone metadata.
        do {
          let metadata = try synchronouslyLoadStringResource(from: phoneMetadata)
          context.evaluateScript(metadata)
          let result = context.evaluateScript("JSON.stringify(i18n.phonenumbers.metadata)")!.toString()!
          let data = result.data(using: .utf8)
            let bytes = (data! as NSData).bytes
            print(bytes)

          let url = baseURL.appendingPathComponent("PhoneNumberMetaData.json")
          try result.write(
            to: url,
            atomically: true,
            encoding: .utf8)
          // Clean up
          context.evaluateScript("i18n.phonenumbers.metadata = null")
        } catch (let error) {
          fputs("Error loading phone number metadata \(error)\n", __stderrp)
          exit(1)
        }

        // Phone metadata for testing.
        do {
          let metadata = try synchronouslyLoadStringResource(from: phoneMetadataForTesting)
          context.evaluateScript(metadata)
          let result = context.evaluateScript("JSON.stringify(i18n.phonenumbers.metadata)")!.toString()!
          let url = baseURL.appendingPathComponent("PhoneNumberMetaDataForTesting.json")
          try result.write(
            to: url,
            atomically: true,
            encoding: .utf8)
        } catch (let error) {
          fputs("Error loading phone number metadata for testing \(error)\n", __stderrp)
          exit(1)
        }

        // Short number metadata.
        do {
          let metadata = try synchronouslyLoadStringResource(from: shortNumberMetadata)
          context.evaluateScript(metadata)
          let result = context.evaluateScript(
            "JSON.stringify(i18n.phonenumbers.shortnumbermetadata)")!.toString()!
          let url = baseURL.appendingPathComponent("ShortNumberMetadata.json")
          try result.write(
            to: url,
            atomically: true,
            encoding: .utf8)
        } catch (let error) {
          fputs("Error loading short number metadata \(error)\n", __stderrp)
          exit(1)
        }

        print("Done")
    }

  // MARK: UISceneSession Lifecycle

  func application(
    _ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return UISceneConfiguration(
      name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }

  func application(
    _ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>
  ) {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
  }
}
