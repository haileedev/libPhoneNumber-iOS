//
//  metadataGenerator.swift
//  libPhoneNumber-iOS
//
//  Created by Paween Itthipalkul on 2/16/18.
//  Copyright © 2018 Google LLC. All rights reserved.
//

import Darwin
import Foundation
import JavaScriptCore

enum GeneratorError: Error {
  case dataNotString
  case genericError
}

func synchronouslyLoadStringResource(from url: URL) throws -> String {
  let session = URLSession(configuration: .default)
  var resultData: Data?
  var resultError: Error?
  let semaphore = DispatchSemaphore(value: 0)

  let dataTask = session.dataTask(with: url) { data, _, error in
    resultData = data
    resultError = error
    semaphore.signal()
  }
  dataTask.resume()

  semaphore.wait()

  if let error = resultError {
    throw error
  }

  if let data = resultData {
    guard let string = String(data: data, encoding: .utf8) else {
      throw GeneratorError.dataNotString
    }

    return string
  }

  throw GeneratorError.genericError
}

func loadJS(from url: URL, to context: JSContext) {
  guard let script = try? synchronouslyLoadStringResource(from: url) else {
    fputs("Cannot load dependency at \(url)\n", __stderrp)
    exit(1)
  }

  context.evaluateScript(script)
}

