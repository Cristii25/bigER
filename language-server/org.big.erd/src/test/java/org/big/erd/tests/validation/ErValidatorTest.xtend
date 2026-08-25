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
	def void testInvalidHierarchyBase() {
		val model = parseHelper.parse('''
			erdiagram Model

			entity Product {
				id key
			}

			hierarchy Product total disjoint
		''')

		validationTestHelper.assertError(
			model.eResource(),
			HIERARCHY,
			EntityRelationshipValidator.INVALID_HIERARCHY_BASE
		)
	}

	@Test
	def void testInvalidHierarchyRoot() {
		val model = parseHelper.parse('''
			erdiagram Model

			entity Person {
				id key
			}

			entity Employee extends Person {
				employee_id key
			}

			entity DeveloperEmployee extends Employee {
				developer_employee_id key
			}

			hierarchy Employee partial disjoint
		''')

		validationTestHelper.assertError(
			model.eResource(),
			HIERARCHY,
			EntityRelationshipValidator.INVALID_HIERARCHY_ROOT
		)
	}

	@Test
	def void testDuplicateHierarchy() {
		val model = parseHelper.parse('''
			erdiagram Model

			entity Person {
				id key
			}

			entity Employee extends Person {
				employee_id key
			}

			hierarchy Person total disjoint
			hierarchy Person partial overlapping
		''')

		validationTestHelper.assertError(
			model.eResource(),
			HIERARCHY,
			EntityRelationshipValidator.DUPLICATE_HIERARCHY
		)
	}
}