// conout_stub.cpp — stub for DoNewAssertDialog (assert_dialog.cpp is MSVC-only;
// mingw/other builds link dbg.cpp which references this function).
// Returns false = "do not break into debugger", so asserts behave like NDEBUG.
// vswprintf is declared dllimport (_CRTIMP) by UCRT headers, producing a
// __imp_vswprintf reference that static libucrt.a cannot satisfy; GNU ld
// auto-import does not fabricate __imp_ aliases from static archives.
// Pre-define _CRTIMP empty so declarations are NOT dllimport; the call then
// resolves directly against the static implementation in libucrt.a.
#if defined(__MINGW32__)
#ifndef _CRTIMP
#define _CRTIMP
#endif
#include <wchar.h>
static int vswprintf_wrapper( wchar_t *b, size_t n, const wchar_t *f, va_list a )
{
	return vswprintf( b, n, f, a );
}
extern "C" void *__imp_vswprintf = (void *)&vswprintf_wrapper;
#endif
// @author codernguoitay @since 2026-11-01
bool DoNewAssertDialog( const char *pFile, int line, const char *pExpression )
{
	(void)pFile; (void)line; (void)pExpression;
	return false;
}
