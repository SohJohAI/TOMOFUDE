import 'dart:html' as html;
import 'dart:convert';
import '../models/novel.dart';
import '../models/work.dart';
import '../models/chapter.dart';

class ExportService {
  // 小説のエクスポート
  void exportAsText(Novel novel, {String? customTitle, String? author}) {
    final content = novel.content;
    final title = customTitle ?? (novel.title.isEmpty ? '無題の小説' : novel.title);
    final formattedDate = DateTime.now().toIso8601String().split('T')[0];
    final authorName = author ?? '匿名';

    final headerText = '$title\n著者: $authorName\n作成日: $formattedDate\n\n';
    final fullContent = headerText + content;

    final blob = html.Blob([fullContent], 'text/plain', 'native');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', '${title}_$formattedDate.txt')
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  void exportAsJson(Novel novel) {
    final jsonData = jsonEncode(novel.toJson());
    final title = novel.title.isEmpty ? '無題の小説' : novel.title;

    final blob = html.Blob([jsonData], 'application/json', 'native');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', '$title.json')
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  void exportAsHtml(Novel novel, {String? customTitle, String? author}) {
    final title = customTitle ?? (novel.title.isEmpty ? '無題の小説' : novel.title);
    final formattedDate = DateTime.now().toIso8601String().split('T')[0];
    final authorName = author ?? '匿名';

    // 段落に分割
    final paragraphs = novel.content.split(RegExp(r'\n\s*\n'));
    final formattedParagraphs = paragraphs
        .map((p) => '    <p>${p.replaceAll('\n', '<br>')}</p>')
        .join('\n');

    final htmlContent = '''
    <!DOCTYPE html>
    <html lang="ja">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>$title</title>
      <style>
        body {
          font-family: 'Hiragino Sans', 'Hiragino Kaku Gothic ProN', 'Noto Sans JP', sans-serif;
          max-width: 800px;
          margin: 0 auto;
          padding: 2rem;
          line-height: 1.8;
          color: #333;
        }
        h1 {
          font-size: 2rem;
          margin-bottom: 0.5rem;
          text-align: center;
        }
        .author {
          text-align: center;
          margin-bottom: 2rem;
          font-size: 1rem;
          color: #666;
        }
        .date {
          text-align: right;
          margin-bottom: 3rem;
          font-size: 0.9rem;
          color: #888;
        }
        p {
          margin-bottom: 1.5rem;
          text-indent: 1em;
        }
        @media print {
          body {
            font-size: 10pt;
            max-width: 100%;
          }
        }
      </style>
    </head>
    <body>
      <h1>$title</h1>
      <div class="author">著者: $authorName</div>
      <div class="date">作成日: $formattedDate</div>
      
    $formattedParagraphs
    </body>
    </html>
    ''';

    final blob = html.Blob([htmlContent], 'text/html', 'native');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', '${title}_$formattedDate.html')
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  // 作品のエクスポート
  void exportWorkAsText(Work work) {
    final title = work.title.isEmpty ? '無題の作品' : work.title;
    final formattedDate = DateTime.now().toIso8601String().split('T')[0];
    final authorName = work.author.isEmpty ? '匿名' : work.author;

    final headerText = '$title\n著者: $authorName\n作成日: $formattedDate\n\n';

    // 各章の内容を結合
    final chaptersContent = work.chapters.asMap().entries.map((entry) {
      final index = entry.key;
      final chapter = entry.value;
      final chapterTitle =
          chapter.title.isEmpty ? '第${index + 1}章' : chapter.title;

      return '# $chapterTitle\n\n${chapter.content}\n\n';
    }).join('\n');

    final fullContent = headerText + chaptersContent;

    final blob = html.Blob([fullContent], 'text/plain', 'native');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', '${title}_$formattedDate.txt')
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  void exportWorkAsJson(Work work) {
    final jsonData = jsonEncode(work.toJson());
    final title = work.title.isEmpty ? '無題の作品' : work.title;

    final blob = html.Blob([jsonData], 'application/json', 'native');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', '$title.json')
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  void exportWorkAsHtml(Work work) {
    final title = work.title.isEmpty ? '無題の作品' : work.title;
    final formattedDate = DateTime.now().toIso8601String().split('T')[0];
    final authorName = work.author.isEmpty ? '匿名' : work.author;

    // 各章のHTMLを生成
    final chaptersHtml = work.chapters.asMap().entries.map((entry) {
      final index = entry.key;
      final chapter = entry.value;
      final chapterTitle =
          chapter.title.isEmpty ? '第${index + 1}章' : chapter.title;

      // 段落に分割
      final paragraphs = chapter.content.split(RegExp(r'\n\s*\n'));
      final formattedParagraphs = paragraphs
          .map((p) => '    <p>${p.replaceAll('\n', '<br>')}</p>')
          .join('\n');

      return '''
      <section class="chapter">
        <h2>$chapterTitle</h2>
        $formattedParagraphs
      </section>
      ''';
    }).join('\n');

    final htmlContent = '''
    <!DOCTYPE html>
    <html lang="ja">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>$title</title>
      <style>
        body {
          font-family: 'Hiragino Sans', 'Hiragino Kaku Gothic ProN', 'Noto Sans JP', sans-serif;
          max-width: 800px;
          margin: 0 auto;
          padding: 2rem;
          line-height: 1.8;
          color: #333;
        }
        h1 {
          font-size: 2rem;
          margin-bottom: 0.5rem;
          text-align: center;
        }
        h2 {
          font-size: 1.5rem;
          margin-top: 3rem;
          margin-bottom: 1.5rem;
          border-bottom: 1px solid #ddd;
          padding-bottom: 0.5rem;
        }
        .author {
          text-align: center;
          margin-bottom: 1rem;
          font-size: 1rem;
          color: #666;
        }
        .date {
          text-align: right;
          margin-bottom: 3rem;
          font-size: 0.9rem;
          color: #888;
        }
        .description {
          margin: 2rem 0;
          padding: 1rem;
          background-color: #f8f8f8;
          border-radius: 5px;
        }
        .chapter {
          margin-bottom: 3rem;
        }
        p {
          margin-bottom: 1.5rem;
          text-indent: 1em;
        }
        @media print {
          body {
            font-size: 10pt;
            max-width: 100%;
          }
          .chapter {
            page-break-after: always;
          }
        }
      </style>
    </head>
    <body>
      <h1>$title</h1>
      <div class="author">著者: $authorName</div>
      <div class="date">作成日: $formattedDate</div>
      
      ${work.description.isNotEmpty ? '<div class="description">${work.description}</div>' : ''}
      
      $chaptersHtml
    </body>
    </html>
    ''';

    final blob = html.Blob([htmlContent], 'text/html', 'native');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', '${title}_$formattedDate.html')
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}

enum ExportFormat {
  text,
  html,
  json,
}
