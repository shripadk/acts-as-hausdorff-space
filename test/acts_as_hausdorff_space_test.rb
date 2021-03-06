require File.dirname(__FILE__) +'/test_helper'

MindoroMarine::Acts::Tests.open_db(ENV['DB'])
class ActsAsHausdorffSpaceTest < Test::Unit::TestCase
  
  def teardown
  HausdorffSpaceTest.delete_all # irritating. I can't get user_transactional_fixtures = true to work outside the rails testing framework
  end
# check all the methods are mixed in  
  should 'mixin methods' do
    rns = HausdorffSpaceTest.new   
    check_method_mixins(rns)
    check_class_method_mixins(HausdorffSpaceTest)
  end
# add one and check that tear down removes it - hence the aa to keep them at the very front of all other tests  
  should "aa add one " do
    r = HausdorffSpaceTest.new(:name=>'top')
    assert r.save
    assert_equal r.left_col_val,r.right_col_val,'for a single record left should equal right'
  end
  
  should 'aa check one' do
    assert_equal 0, HausdorffSpaceTest.count, "the teardown didn't clear out the test table" 
  end
  
  should 'set left and right cols' do
    assert_equal('left_col',HausdorffSpaceTest.left_col_name,'class attribute left col not working')
    assert_equal('right_col',HausdorffSpaceTest.right_col_name,'class attribute right col not working')
  end
  
  
####### Test Class Methods #######
context 'Class Methods - Add a Root' do
   setup do
   @hst = HausdorffSpaceTest.create(:name=>'top 1')
   end
   
   should "set in_tree_load to true" do
   HausdorffSpaceTest.in_tree_load = true
   assert HausdorffSpaceTest.in_tree_load?,'in tree load was not set to true'
   end
   
   should "set in_tree_load to false" do
   HausdorffSpaceTest.in_tree_load = false
   assert !HausdorffSpaceTest.in_tree_load?,'in tree load was not set to false'
   end
   
   should 'read root and virtual root' do
       read_root = HausdorffSpaceTest.root
       assert_equal @hst,HausdorffSpaceTest.root,'The first root should be the saved record' 
       assert_equal(HausdorffSpaceTest.virtual_root, HausdorffSpaceTest.root.parent,'The virtual root should be the parent of a root node')
       assert_not_nil read_root.right_col_val, 'read_root.rgt is nil'
       assert_equal read_root.right_col_val, read_root.left_col_val, 'left != rgt'
       assert_equal [],read_root.children, 'hs_children is not empty'
   end 
   
   should 'allow other roots to be added' do      
       HausdorffSpaceTest.create(:name=>'top 2')
       read_roots = HausdorffSpaceTest.roots
       assert_equal(2,read_roots.size,'failed to get multiple roots')
       assert_not_equal(read_roots[0].left_col_val,read_roots[1].left_col_val,'the roots have the same left col values')
    end
    
    # records with lft=rgt=null are not roots
    should 'not identify records with lft and rgt = null as roots' do
     HausdorffSpaceTest.connection.update_sql("update hausdorff_space_tests set #{HausdorffSpaceTest.left_col_name} = null,  #{HausdorffSpaceTest.right_col_name} = null  " )
     assert_equal 0,HausdorffSpaceTest.roots.size 
    end
     # an existing record with lft or rgt set should be able to become a root
    should "allow an existing record in the tree to become a root"  do
   
    end
    
    # an existing record without lft or rgt set should be able to become a root
    should "allow an existing record not in the tree to become a root"  do
    
    end
    
    
 end # context
# instance methods
context 'Instance Methods - Add a Root' do
   setup do
  # puts "************ create a root ************"
   @hst = HausdorffSpaceTest.create(:name=>'top 1')
  # check_root = HausdorffSpaceTest.find @hst.id
  # puts check_root 
   end
   
    # the parent should be able to be set via record.children << another_record
  should 'set the parent by <<' do
      r = HausdorffSpaceTest.new(:name=>'top')
      HausdorffSpaceTest.roots
      HausdorffSpaceTest.virtual_root.children << r
      r.save
      assert !r.new_record? # should have been saved
      assert_equal HausdorffSpaceTest.virtual_root,r.parent, ' << the parent is not a virtual root'
  end
  
  # the parent should be able to be set via another_record.parent =  << record
  should 'set the parent by parent = ' do
      r = HausdorffSpaceTest.new(:name=>'top')
      HausdorffSpaceTest.roots
      r.parent = HausdorffSpaceTest.virtual_root
      r.save
      assert !r.new_record?
      assert_equal r,HausdorffSpaceTest.virtual_root.children[1],' = the parent is not a virtual root'
  end
  
 context 'add one child to root' do
   setup do
   # puts "************ add one child ***********"
    @sub_level = HausdorffSpaceTest.new(:name=>'child 1') 
   # puts "id = #{@sub_level.id} lft = #{@sub_level.left_col} rgt = #{@sub_level.right_col}"  
    @hst.children << @sub_level 
   # puts "id = #{@sub_level.id} lft = #{@sub_level.left_col} rgt = #{@sub_level.right_col}"
   # puts "root = #{@hst.id} lft = #{@hst.left_col} rgt = #{@hst.right_col}"   
   end 
   
  should 'link parent and child' do
    validate_parent_one_child_settings(@hst,@sub_level)
    root = HausdorffSpaceTest.find @hst.id
   # puts root
    assert_equal @hst,@sub_level.my_root,'my root is not the parent'
   end 
   
  should 'read parent and child back' do
   full_tree = HausdorffSpaceTest.full_tree
   validate_parent_one_child_settings(full_tree,full_tree.children[0])
   assert_equal full_tree,full_tree.children[0].my_root
   end  
   
  
  
  # this definitly should not be allowed since we can't have an infinite loop
  should 'not allow a parent to be its own parent' do
  
  end
  
  # daft idea but in theory it's possible to have root->parent->child changing to root->child->parent
  should "allow a parent to become a child of one of its children" do
  
  end 
  end # context "add one child to root" 
  
  context 'add many children' do
   setup do
  # puts "in tree #{HausdorffSpaceTest.in_tree_load?}"
   (0..4).each{|n| @hst.children << HausdorffSpaceTest.new(:name=>"child #{n}")  }
  # puts "children size #{@hst.children.size}"
   @hst.save
   end
   
   should 'have gaps between children' do
    read_root = HausdorffSpaceTest.full_tree
    assert_equal 5,read_root.children.size
    (1..4).each do |n| 
    assert read_root.children[n-1].right_col_val < read_root.children[n].left_col_val,' there should be a gap between each child' 
    end
   end
   
   should 'move a child to an child of another' do    
    @hst.children.first.children << @hst.children.last 
    read_root = HausdorffSpaceTest.full_tree
    assert_equal 4,read_root.children.size,"the child didn't get moved"
    assert_equal 1,read_root.children.first.children.size,"the child didn't appear in the right place"     
   end
   
   should 'allow editing one child on its own' do
   all_recs = HausdorffSpaceTest.find :all
   rec = all_recs[3]
   lft = rec.left_col
   rgt = rec.right_col
   id = rec.id
   rec.name = 'new name'
   rec.save
   read_rec = HausdorffSpaceTest.find id
   assert_equal lft,read_rec.left_col,'the left column is wrong on a read read'
   assert_equal rgt,read_rec.right_col,'the right column is wrong on a read read' 
   end
  end # context 'add many children' 
  
  context 'add many grandchildren' do
   setup do
   (0..4).each do |n1|
   new_child =  HausdorffSpaceTest.new(:name=>"child #{n1}")
   @hst.children << new_child
     (0..4).each do |n2| 
     new_child.children << HausdorffSpaceTest.new(:name=>"grandchild #{n2} of child #{n1} ")
     end
   end
   end # setup
   
   should 'count all leaf nodes ' do
    assert_equal 25,@hst.leaf_nodes.size,'error counting leaf nodes'
   end
   
   should 'move whole branches' do
   @hst.children.first.children << @hst.children.last
   read_root = HausdorffSpaceTest.full_tree
   assert_equal 4,read_root.children.size
   assert_equal 6,read_root.children.first.children.size
   assert_equal 10,read_root.children.first.leaf_nodes.size 
   end
   
   should 'get self and ancestors' do
   saa = @hst.children.first.children.first.self_and_ancestors
   assert_equal 3, saa.size, 'There should be three records'
   assert_equal @hst,saa[0], 'The first ancestor should be the top level owner'
   assert_equal @hst.children.first, saa[1],'The second ancestor should be child of the top level '
   assert_equal @hst.children.first.children.first, saa[2],'The third ancestor should be this record'
   end
   
   should 'get only ancestors' do
   a = @hst.children.first.children.first.ancestors
   assert_equal 2, a.size, 'There should be two records'
   assert !a.include?(@hst.children.first.children.first),' this record should not be in the array'
   end
   
   should 'get self and siblings' do
   sas = @hst.children.first.children.first.self_and_siblings
   assert_equal 5,sas.size, 'There should be five records in self and siblings'
   sas.each do |rec|
     assert_equal @hst.children.first,rec.parent,'each sibling must have the same parent'
   end
   end
   
   should 'get only siblings' do
   s = @hst.children.first.children.first.siblings
   assert_equal 4,s.size, 'There should be four records in siblings'
   assert !s.include?(@hst.children.first.children.first),'This record should not be in the array of siblings'
   end
   
  end # context 'add many grandchildren' do
  
end # context  'Instance Methods - Add a Root'    
private ############################ PRIVATE ##########################################  
 def check_method_mixins(obj)
   [:build_full_tree,
    :before_save,
    :siblings,
    :left_col_val,
    :right_col_val].each{|symbol| assert(obj.respond_to?(symbol),"instance method #{symbol} is missing")}
  end
  
  def check_class_method_mixins(klass)
    [:root, 
     :roots,
     :left_col_name,
     :right_col_name,
     :full_tree,
     :virtual_root].each do |symbol|
    assert(klass.respond_to?(symbol),"class method #{symbol} is missing")
    end   
  end
  
 def validate_parent_one_child_settings(parent,child)
   assert_not_nil parent,'the parent should exist'
   assert_not_nil child,'the child should exist'
   assert_equal parent,child.parent,'the sublevel should have a parent'
   assert_equal child,parent.children[0], 'the parent should own the child'
   assert_not_equal parent.left_col_val,child.left_col_val, 'there should be a gap between the parent left and the child left'
   assert_not_equal parent.right_col_val,child.right_col_val, 'there should be a gap between the parent right and the child right '
   assert parent.left_col_val < child.left_col_val,' the parent left should be less that the child left'
   assert parent.right_col_val > child.right_col_val, ' the parent right should be more that the child right'
   assert_equal parent.left_col_val,child.lft_gap.left_col_val,'the parent left should be the left of the childs left gap'
   assert_equal child.left_col_val,child.lft_gap.right_col_val,'the child left should be the right of the child left gap'
   assert_equal parent.right_col_val,child.rgt_gap.right_col_val,'the parent right should be the right of the child right gap'
   assert_equal child.right_col_val,child.rgt_gap.left_col_val,' the child right should the the left of the child right gap'
 end
end
