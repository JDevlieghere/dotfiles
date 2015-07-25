import os
import os.path
import fnmatch

base_flags = [
	'-Wall',
	'-Wextra',
	'-Werror',
	'-Wc++98-compat',
	'-Wno-long-long',
	'-Wno-variadic-macros',
	'-fexceptions',
	'-DNDEBUG',
	'-std=c++98',
	'-xc++',
	'-I/usr/include/'
]

def FindNearest(path, target):
	candidate = os.path.join(path, target)
	if(os.path.isfile(candidate) or os.path.isdir(candidate)):
		return candidate;
	else:
		parent = os.path.dirname(os.path.abspath(path));
		if(parent == path):
			raise RuntimeError("Could not find " + target);
		return FindNearest(parent, target)

def FlagsForClangComplete(root):
	try:
		clang_complete_path = FindNearest(root, '.clang_complete')
		clang_complete_flags = open(clang_complete_path, 'r').read().splitlines()
		return clang_complete_flags
	except:
		return []

def FlagsForInclude(root):
	flags = []
	try:
		include_path = FindNearest(root, 'include')
		for dirroot, dirnames, filenames in os.walk(include_path):
			for dir_path in dirnames:
				real_path = os.path.join(dirroot, dir_path)
				flags = flags + ['-I', real_path]
	except:
		pass
	return flags


def FlagsForFile(filename):
	root = os.path.realpath(filename);
	flags = base_flags + FlagsForClangComplete(root) + FlagsForInclude(root)
	return {
		'flags': flags,
		'do_cache': True
	}
