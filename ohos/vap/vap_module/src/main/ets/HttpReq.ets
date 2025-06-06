/*
 * Copyright (C) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { http } from '@kit.NetworkKit';
import fs from '@ohos.file.fs';
import { DownloadData } from './DataDeclare'

function extractFileName(url: string): string {
  // 使用正则表达式匹配 URL 中的文件名部分
  const matches = url.match(/\/([^\/?#]+)[^\/]*$/);
  if (matches && matches.length > 1) {
    return matches[1];
  }
  // 如果没有匹配到，则返回空字符串或者你想要的默认值
  return '';
}

function startsWithHttp(url: string): boolean {
  return url.startsWith("http");
}

function writeFile(filePath: string, buf: ArrayBuffer) {
  let file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
  fs.writeSync(file.fd, buf);
  fs.closeSync(file);
}

export async function downloadFile(url: string, downloadTimeout: number, dir?: string, callback?: (data: DownloadData) => void) {
  console.log('enter downloadFile: ' + JSON.stringify(url));
  if(!startsWithHttp(url)) {
    return url;
  }
  const fileName = extractFileName(url);
  let filePath = `${getContext().filesDir}/${fileName}`;
  if(dir) {
    filePath = dir + '/' + fileName
  }
  let res = fs.accessSync(filePath);
  if (res) {
    return filePath;
  }

  let httpRequest = http.createHttp();
  try {
    let res = new ArrayBuffer(0);
    httpRequest.on('dataReceive', (data: ArrayBuffer) => {
      const newRes = new ArrayBuffer(res.byteLength + data.byteLength);
      const resView = new Uint8Array(newRes);
      resView.set(new Uint8Array(res));
      resView.set(new Uint8Array(data), res.byteLength);
      res = newRes;
    });

    httpRequest.on('dataReceiveProgress', (data: DownloadData) => {
      if (callback) {
        callback(data);
      }
    });

    await httpRequest.requestInStream(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        readTimeout: downloadTimeout,
      }).then((data: number) => {
      console.info('ResponseCode :' + JSON.stringify(data));
      httpRequest.off('dataReceive');
      httpRequest.off('dataReceiveProgress');
    })
    writeFile(filePath, res)
  } catch (err) {
    console.error("accessSync failed with error message: " + err.message + ", error code: " + err.code);
    filePath = ''
  } finally {
    httpRequest.destroy();
  }
  return filePath
}
