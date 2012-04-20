# Copyright (C) 2012 Matthias Lederhofer <matled@gmx.net>
#
# This file is part of fned.
#
# fned is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# fned is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with fned.  If not, see <http://www.gnu.org/licenses/>.
require 'fned/filename_edit'

module Fned
  def self.main(*args, &block)
    FilenameEdit.main(*args, &block)
  end
end
