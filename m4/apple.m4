# serial 1

# The following code has been found in several open source projects online.
# It's true origin is unknown.
#
# AC_CHECK_FRAMEWORK(FRAMEWORK, FUNCTION,
#              [ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND],
#              [OTHER-LIBRARIES])
# ------------------------------------------------------
#
AC_DEFUN([AC_CHECK_FRAMEWORK],
[m4_ifval([$3], , [AH_CHECK_FRAMEWORK([$1])])dnl
AS_LITERAL_IF([$1],
         [AS_VAR_PUSHDEF([ac_Framework], [ac_cv_framework_$1_$2])],
         [AS_VAR_PUSHDEF([ac_Framework], [ac_cv_framework_$1''_$2])])dnl
AC_CACHE_CHECK([for $2 in $1 framework], ac_Framework,
[ac_check_framework_save_LIBS=$LIBS
LIBS="-framework $1 $5 $LIBS"
AC_LINK_IFELSE([AC_LANG_CALL([], [$2])],
          [AS_VAR_SET(ac_Framework, yes)],
          [AS_VAR_SET(ac_Framework, no)])
LIBS=$ac_check_framework_save_LIBS])
AS_IF([test AS_VAR_GET(ac_Framework) = yes],
      [m4_default([$3], [AC_DEFINE_UNQUOTED(AS_TR_CPP(HAVE_FRAMEWORK_$1))
  LIBS="-framework $1 $LIBS"
])],
      [$4])dnl
AS_VAR_POPDEF([ac_Framework])dnl
])# AC_CHECK_FRAMEWORK

# AH_CHECK_FRAMEWORK(FRAMEWORK)
# ---------------------
m4_define([AH_CHECK_FRAMEWORK],
[AH_TEMPLATE(AS_TR_CPP(HAVE_FRAMEWORK_$1),
        [Define to 1 if you have the `]$1[' framework (-framework ]$1[).])])


## ------------------------------- ##
## Check for Apple Mac OS X        ##
## ------------------------------- ##

AC_DEFUN([GP_APPLE],
[AC_MSG_CHECKING(for Apple Mac OS X)
AC_EGREP_CPP(yes,
[#if defined(__APPLE__) && defined(__MACH__)
  yes
#endif
],
   [AC_MSG_RESULT(yes)
    is_apple=yes],
   [AC_MSG_RESULT(no)
    is_apple=no])

dnl  AquaTerm terminal for Mac OS X

dnl The terminal only works on Mac OS X, so the test will only be performed there
dnl It is enabled by default (if AquaTerm can be found).
dnl One can disabled it with --without-aquaterm
dnl or choose a different framework location with --with-aquaterm=/path/to/Frameworks
dnl
dnl Somewhere we have to document that --with-aquaterm=/path/to/Frameworks will try to include
dnl       /path/to/Frameworks/AquaTerm.framework by using -F/path/to/Frameworks
dnl as well as
dnl       -I/path/to/Frameworks/AquaTerm.framework/Headers
dnl but of course one can always simply use explicit LDFLAGS and CFLAGS.

if test "$is_apple" = "yes"; then
    AC_ARG_WITH(aquaterm, [  --without-aquaterm      disable aqua terminal (default --with-aquaterm=/Library/Frameworks)], [], [with_aquaterm="yes"])

    # if AquaTerm wasn't explicitly disabled
    if test "x$with_aquaterm" != xno; then
        aquaterm_libs=""
        AS_IF([test "x$with_aquaterm" = xyes],
              # Default location of AquaTerm framework
              [aquaterm_framework_path="/Library/Frameworks"],
              # Location of frameworks provided by user
              [aquaterm_framework_path="$with_aquaterm"
               aquaterm_libs=" -F$aquaterm_framework_path"])

        dnl Test if /path/to/Frameworks/AquaTerm.framework as provided by
        dnl     --with-aquaterm=/path/to/Frameworks or /Library/Frameworks
        dnl exists and issue a warning if it doesn't
        dnl (however it might still be the case that one used explicit flags, so don't make that fatal, just informative)
        AS_IF([test ! -d "$aquaterm_framework_path/AquaTerm.framework"],
              [AC_MSG_WARN([Framework '$aquaterm_framework_path/AquaTerm.framework' doesn't exist.])
               aquaterm_libs=""])

        dnl We need to check if AquaTerm/AQTAdapter.h can be found.
        dnl We could actually use AC_LANG_PUSH([Objective C]) here, but for real compilation C with -ObjC is used
        dnl and it might be that users have set CFLAGS and no OBJCFLAGS, which would lead to discrepancies.
        ac_save_CFLAGS="$CFLAGS"
        CFLAGS="$CFLAGS -ObjC$aquaterm_libs"
        AC_LANG_PUSH([C])
        AC_CACHE_CHECK([for AquaTerm/AQTAdapter.h],
                       [ac_cv_header_aquaterm_aqtadapter_h],
                       [AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[#import <AquaTerm/AQTAdapter.h>]],[[]])],
                                          [ac_cv_header_aquaterm_aqtadapter_h=yes],
                                          [ac_cv_header_aquaterm_aqtadapter_h=no])])
        AC_LANG_POP([C])
        CFLAGS="$ac_save_CFLAGS"

        dnl And now finally test if AquaTerm framework can be linked against
        AS_IF([test "x$ac_cv_header_aquaterm_aqtadapter_h" = "xno"],
              [with_aquaterm=no],
              [AC_CHECK_FRAMEWORK([AquaTerm],[aqtInit],
                                  [AC_DEFINE(HAVE_LIBAQUATERM,1,
                                      [Define to 1 if you're using the AquaTerm framework on Mac OS X])
                                   CFLAGS="$CFLAGS -ObjC$aquaterm_libs"
                                   LIBS="$LIBS -framework Foundation -framework AquaTerm$aquaterm_libs"
                                   with_aquaterm=yes
                                  ],[with_aquaterm=no],[$aquaterm_libs])])
    fi
else
    with_aquaterm=no
fi

])
