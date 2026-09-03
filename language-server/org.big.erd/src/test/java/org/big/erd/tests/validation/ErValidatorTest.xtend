package org.big.erd.tests.validation

import org.junit.jupiter.api.^extension.ExtendWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import com.google.inject.Inject
import org.eclipse.xtext.testing.InjectWith
import org.junit.jupiter.api.Test
import org.big.erd.tests.EntityRelationshipInjectorProvider
import org.eclipse.xtext.testing.util.ParseHelper
import org.big.erd.entityRelationship.Model
import org.eclipse.xtext.testing.validation.ValidationTestHelper
import org.big.erd.validation.EntityRelationshipValidator
import static org.big.erd.entityRelationship.EntityRelationshipPackage.Literals.*

@ExtendWith(InjectionExtension)
@InjectWith(EntityRelationshipInjectorProvider)
class ErValidatorTest {
	
	@Inject ParseHelper<Model> parseHelper
	@Inject ValidationTestHelper validationTestHelper
	
	@Test
	def void testMissingPrimaryKey() {
		val model = parseHelper.parse('''
			erdiagram Model
			entity Entity1 {}
		''')
		validationTestHelper.assertWarning(
			model.eResource(), 
			ENTITY, 
			EntityRelationshipValidator.MISSING_PRIMARY_KEY
		)
	}
	
	@Test
	def void testMissingPartialKey() {
		val model = parseHelper.parse('''
			erdiagram Model
			weak entity Entity1 {}
		''')
		validationTestHelper.assertWarning(
			model.eResource(), 
			ENTITY, 
			EntityRelationshipValidator.MISSING_PARTIAL_KEY
		)
	}
	
	@Test
	def void testInvalidCardinality() {
		val model = parseHelper.parse('''
			erdiagram Model
			notation=bachman
			entity Entity1 {
				id key
			}
			entity Entity2 {
				id key
			}
			relationship Rel {
				Entity1[1] -> Entity2
			}
		''')
		val rel = model.relationships.get(0)
		validationTestHelper.assertWarning(
			model.eResource(), 
			rel.second.eClass, 
			EntityRelationshipValidator.INVALID_CARDINALITY
		)
	}

	@Test
	def void testHierarchyWithoutSubclasses() {
		val model = parseHelper.parse('''
			erdiagram Model

			entity Product {
				id key
			}

			hierarchy h_product Product partial
		''')

		validationTestHelper.assertError(
			model.eResource(),
			HIERARCHY,
			EntityRelationshipValidator.HIERARCHY_WITHOUT_SUBCLASSES
		)
	}

	@Test
	def void testSingleSubclassHierarchyMustBePartial() {
		val model = parseHelper.parse('''
			erdiagram Model

			entity Person {
				id key
			}

			hierarchy h_employee Person total

			entity Employee extends h_employee {
				id key
			}
		''')

		validationTestHelper.assertError(
			model.eResource(),
			HIERARCHY,
			EntityRelationshipValidator.INVALID_SINGLE_SUBCLASS_HIERARCHY
		)
	}

	@Test
	def void testSingleSubclassHierarchyCannotHaveConstraint() {
		val model = parseHelper.parse('''
			erdiagram Model

			entity Person {
				id key
			}

			hierarchy h_employee Person partial disjoint

			entity Employee extends h_employee {
				id key
			}
		''')

		validationTestHelper.assertError(
			model.eResource(),
			HIERARCHY,
			EntityRelationshipValidator.INVALID_SINGLE_SUBCLASS_HIERARCHY
		)
	}

	@Test
	def void testMultipleSubclassesRequireConstraint() {
		val model = parseHelper.parse('''
			erdiagram Model

			entity Person {
				id key
			}

			hierarchy h_person Person partial

			entity Employee extends h_person {
				id key
			}

			entity Customer extends h_person {
				id key
			}
		''')

		validationTestHelper.assertError(
			model.eResource(),
			HIERARCHY,
			EntityRelationshipValidator.MISSING_HIERARCHY_CONSTRAINT
		)
	}

	@Test
	def void testMultipleHierarchiesCanHaveSameBase() {
		val model = parseHelper.parse('''
			erdiagram Model

			entity Employee {
				id key
			}

			hierarchy h_job Employee partial
			hierarchy h_management Employee partial

			entity Technician extends h_job {
				id key
			}

			entity Manager extends h_management {
				id key
			}
		''')

		validationTestHelper.assertNoErrors(model)
	}

	@Test
	def void testMultilevelHierarchyIsValid() {
		val model = parseHelper.parse('''
			erdiagram Model

			entity Person {
				id key
			}

			hierarchy h_person Person partial

			entity Employee extends h_person {
				id key
			}

			hierarchy h_employee Employee partial

			entity Developer extends h_employee {
				id key
			}
		''')

		validationTestHelper.assertNoErrors(model)
	}

	@Test
	def void testSubclassMustDeclareSameKeyAsSuperclass() {
		val model = parseHelper.parse('''
			erdiagram Model

			entity Person {
				id key
			}

			hierarchy h_person Person partial

			entity Employee extends h_person {
				employee_id key
			}
		''')

		validationTestHelper.assertError(
			model.eResource(),
			ENTITY,
			EntityRelationshipValidator.INVALID_SUBCLASS_KEY
		)
	}

	@Test
	def void testDuplicateHierarchyName() {
		val model = parseHelper.parse('''
			erdiagram Model

			entity Person {
				id key
			}

			entity Employee {
				id key
			}

			hierarchy h_type Person partial
			hierarchy h_type Employee partial

			entity Customer extends h_type {
				id key
			}
		''')

		validationTestHelper.assertError(
			model.eResource(),
			HIERARCHY,
			EntityRelationshipValidator.DUPLICATE_HIERARCHY_NAME
		)
	}

	@Test
	def void testWeakEntityCannotBeHierarchyBase() {
		val model = parseHelper.parse('''
			erdiagram Model

			weak entity WeakEntity {
				id
			}

			hierarchy h_weak WeakEntity partial

			entity Child extends h_weak {
				id key
			}
		''')

		validationTestHelper.assertError(
			model.eResource(),
			HIERARCHY,
			EntityRelationshipValidator.INVALID_HIERARCHY_BASE
		)
	}

	@Test
	def void testAssociativeEntityCannotDeclareKey() {
		val model = parseHelper.parse('''
			erdiagram Model

			associative entity Enrollment {
				id key
			}
		''')

		validationTestHelper.assertError(
			model.eResource(),
			ENTITY,
			EntityRelationshipValidator.INVALID_ASSOCIATIVE_KEY
		)
	}

	@Test
	def void testAssociativeEntityCannotDeclarePartialKey() {
		val model = parseHelper.parse('''
			erdiagram Model

			associative entity Enrollment {
				id partial-key
			}
		''')

		validationTestHelper.assertError(
			model.eResource(),
			ENTITY,
			EntityRelationshipValidator.INVALID_ASSOCIATIVE_KEY
		)
	}

	@Test
	def void testAssociativeEntityWithoutAttributesIsValid() {
		val model = parseHelper.parse('''
			erdiagram Model

			associative entity Enrollment {
			}
		''')

		validationTestHelper.assertNoErrors(model)
	}

	@Test
	def void testAssociativeEntityCannotBeHierarchyBase() {
		val model = parseHelper.parse('''
			erdiagram Model

			associative entity Enrollment {
				date
			}

			hierarchy h_enrollment Enrollment partial

			entity EnrollmentChild extends h_enrollment {
			}
		''')

		validationTestHelper.assertError(
			model.eResource(),
			HIERARCHY,
			EntityRelationshipValidator.INVALID_HIERARCHY_BASE
		)
	}	

	@Test
	def void testHierarchyCycle() {
		val model = parseHelper.parse('''
			erdiagram Model

			entity EntityA extends h_b {
				id key
			}

			entity EntityB extends h_a {
				id key
			}

			hierarchy h_a EntityA partial
			hierarchy h_b EntityB partial
		''')

		validationTestHelper.assertError(
			model.eResource(),
			HIERARCHY,
			EntityRelationshipValidator.INVALID_HIERARCHY_CYCLE
		)
	}
}