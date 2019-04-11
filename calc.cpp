#include <cstdio>
#include <cstdlib>

enum PARSE_ERR { NO_ERR, PARENTHESIS, WRONG_CHAR, DIV_ZERO };

int parent_count{0};
PARSE_ERR err{NO_ERR};
int parse_add_sub(char*& eval);

int parse_char(char*& eval) {
  while (*eval == ' ') {
    ++eval;
  }
  bool negative = false;
  if (*eval == '-') {
    negative = true;
    ++eval;
  }
  if (*eval == '+') {
    ++eval;
  }
  if (*eval == '(') {
    ++eval;
    ++parent_count;
    int res = parse_add_sub(eval);
    if (*eval != ')') {
      err = PARENTHESIS;
      return 0;
    }
    ++eval;
    --parent_count;
    if (negative) {
      return -res;
    } else {
      return res;
    }
  }
  char* end_str;
  int res = std::strtod(eval, &end_str);
  if (end_str == eval) {
    err = WRONG_CHAR;
    return 0;
  }
  eval = end_str;
  if (negative) {
    return -res;
  } else {
    return res;
  }
}

int parse_mul_div(char*& eval) {
  int num1 = parse_char(eval);
  for (;;) {
    while (*eval == ' ') {
      ++eval;
    }
    char op = *eval;
    if (op != '/' && op != '*') {
      return num1;
    }
    ++eval;
    int num2 = parse_char(eval);
    if (op == '/') {
      if (num2 == 0) {
        err = DIV_ZERO;
        return 0;
      }
      num1 /= num2;
    } else {
      num1 *= num2;
    }
  }
}

int parse_add_sub(char*& eval) {
  int num1 = parse_mul_div(eval);
  for (;;) {
    while (*eval == ' ') {
      ++eval;
    }
    char op = *eval;
    if (op != '-' && op != '+') {
      return num1;
    }
    ++eval;
    int num2 = parse_mul_div(eval);
    if (op == '-') {
      num1 -= num2;
    } else {
      num1 += num2;
    }
  }
}

int eval(char* eval) {
  int res = parse_add_sub(eval);
  if (parent_count != 0 || *eval == ')') {
    err = PARENTHESIS;
    return 0;
  }
  if (*eval != '\0') {
    err = WRONG_CHAR;
    return 0;
  }
  return res;
}

int main(int argc, char** argv) {
  int res = eval(argv[1]);
  printf("%d", res);
  return err;
}