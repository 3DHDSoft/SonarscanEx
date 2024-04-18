/// <summary>
/// Simple regex commit linter example
/// https://www.conventionalcommits.org/en/v1.0.0/
/// https://github.com/angular/angular/blob/22b96b9/CONTRIBUTING.md#type
/// https://github.com/alirezanet/Husky.Net/blob/master/.husky/csx/commit-lint.csx
/// </summary>

using System.Text.RegularExpressions;

// Sample commit massage: fix(api): Added new user API
// RegEx Test: https://regex101.com/
// Regex cookbook - https://medium.com/@fox.jonny/regex-cookbook-most-wanted-regex-aa721558c3c1
// Lookahead and Lookbehind Zero-Length Assertions - https://www.regular-expressions.info/lookaround.html
// https://regex101.com/r/zzhtnP/1
private var conventionalCommitPattern = @"^(?=.{1,90}$)(?:build|feat|ci|chore|docs|fix|perf|refactor|revert|style|test)(?:\(.+\))*(?::).{4,}(?:#\d+)*(?<![\.\s])$";

// Sample commit massage: fix(api): Added new user API
// Lookahead and Lookbehind Zero-Length Assertions - https://www.regular-expressions.info/lookaround.html
private var taskPattern = @"[a-z0-9]{9}(?= )"; // https://regex101.com/r/cFYWjO/1

private var msg = File.ReadAllLines(Args[0])[0];

if (Regex.IsMatch(msg, conventionalCommitPattern))
{
  if (Regex.IsMatch(msg, taskPattern))
  {
    return 0;
  }
  else {
    Console.ForegroundColor = ConsoleColor.Red;
    Console.WriteLine("Invalid commit message.");
    Console.ResetColor();
    Console.WriteLine("Missind Card info e.g: '12t4f6789'");
    Console.ForegroundColor = ConsoleColor.Gray;

    return 1;
  }
}

Console.ForegroundColor = ConsoleColor.Red;
Console.WriteLine("Invalid commit message.");
Console.ResetColor();
Console.WriteLine("e.g: 'feat(scope): subject' or 'fix: subject'");
Console.ForegroundColor = ConsoleColor.Gray;
Console.WriteLine("more info: https://www.conventionalcommits.org/en/v1.0.0/");

return 1;
