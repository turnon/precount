require 'test_helper'

class PrecountPathTest < Minitest::Test
  Teacher = Struct.new(:n) do
    def lessons
      @lessons ||= []
    end
  end

  Lesson = Struct.new(:n) do
    def students
      @students ||= []
    end
  end

  Student = Struct.new(:n)

  def setup
    t1 = Teacher.new 1
    t2 = Teacher.new 2

    l1 = Lesson.new 1
    l2 = Lesson.new 3
    l3 = Lesson.new 3

    t1.lessons << l1 << l2
    t2.lessons << l2 << l3

    @s1 = Student.new 1
    @s2 = Student.new 2
    @s3 = Student.new 3
    @s4 = Student.new 4
    @s5 = Student.new 5
    @s6 = Student.new 6

    l1.students << @s1 << @s2 << @s3
    l2.students << @s3 << @s4 << @s5
    l3.students << @s5 << @s6 << @s1

    @teachers = [t1, t2]
  end

  def test_flat_map
    path = Precount::Path.new :lessons, :students
    result = [@s1, @s2, @s3, @s3, @s4, @s5, @s3, @s4, @s5, @s5, @s6, @s1]
    assert_equal result, path.endpoints(@teachers)
  end
end
