<?php

declare(strict_types=1);

use Rector\CodeQuality\Rector\Class_\DynamicDocBlockPropertyToNativePropertyRector;
use Rector\CodeQuality\Rector\ClassMethod\ExplicitReturnNullRector;
use Rector\CodeQuality\Rector\Concat\DirnameDirConcatStringToDirectStringPathRector;
use Rector\CodingStyle\Rector\ArrowFunction\StaticArrowFunctionRector;
use Rector\CodingStyle\Rector\Assign\NestedTernaryToMatchRector;
use Rector\CodingStyle\Rector\Catch_\CatchExceptionNameMatchingTypeRector;
use Rector\CodingStyle\Rector\ClassMethod\MakeInheritedMethodVisibilitySameAsParentRector;
use Rector\CodingStyle\Rector\ClassMethod\NewlineBeforeNewAssignSetRector;
use Rector\CodingStyle\Rector\Closure\StaticClosureRector;
use Rector\CodingStyle\Rector\Encapsed\EncapsedStringsToSprintfRector;
use Rector\CodingStyle\Rector\FuncCall\ArraySpreadInsteadOfArrayMergeRector;
use Rector\CodingStyle\Rector\FuncCall\StrictArraySearchRector;
use Rector\CodingStyle\Rector\Stmt\NewlineAfterStatementRector;
use Rector\Config\RectorConfig;
use Rector\Doctrine\Orm30\Rector\MethodCall\SetParametersArrayToCollectionRector;
use Rector\Php55\Rector\String_\StringClassNameToClassConstantRector;
use Rector\Php73\Rector\FuncCall\JsonThrowOnErrorRector;
use Rector\Php80\Rector\Class_\ClassPropertyAssignToConstructorPromotionRector;
use Rector\Php82\Rector\Param\AddSensitiveParameterAttributeRector;
use Rector\TypeDeclaration\Rector\ClassMethod\AddParamArrayDocblockBasedOnCallableNativeFuncCallRector;
use Rector\TypeDeclaration\Rector\ClassMethod\AddParamFromDimFetchKeyUseRector;
use Rector\TypeDeclaration\Rector\ClassMethod\AddReturnArrayDocblockBasedOnArrayMapRector;
use Rector\TypeDeclaration\Rector\ClassMethod\StrictArrayParamDimFetchRector;
use Rector\TypeDeclaration\Rector\StmtsAwareInterface\DeclareStrictTypesRector;
use Rector\TypeDeclaration\Rector\StmtsAwareInterface\SafeDeclareStrictTypesRector;

return RectorConfig::configure()
    ->withPaths([
        __DIR__ . '/src',
        __DIR__ . '/tests',
    ])
    ->withImportNames(importShortClasses: false)
    ->withPreparedSets(
        deadCode: true,
        codeQuality: true,
        privatization: true,
        instanceOf: true,
        earlyReturn: true,
        codingStyle: true,
        typeDeclarations: true,
        rectorPreset: true,
    )
    ->withRules([
        ArraySpreadInsteadOfArrayMergeRector::class,
        StaticArrowFunctionRector::class,
        StringClassNameToClassConstantRector::class,
        DynamicDocBlockPropertyToNativePropertyRector::class,
        AddParamArrayDocblockBasedOnCallableNativeFuncCallRector::class,
        AddReturnArrayDocblockBasedOnArrayMapRector::class,
        JsonThrowOnErrorRector::class,
        StaticClosureRector::class,
        NestedTernaryToMatchRector::class,
        DirnameDirConcatStringToDirectStringPathRector::class,
        SafeDeclareStrictTypesRector::class,
    ])
    ->withConfiguredRule(AddSensitiveParameterAttributeRector::class, [
        AddSensitiveParameterAttributeRector::SENSITIVE_PARAMETERS => [
            'password',
            'newPassword',
            'contraseña',
            'nuevaContraseña',
            'oldPassword',
            'token',
            'username',
            'database',
        ],
    ])
    ->withPhpSets()
;
